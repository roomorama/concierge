module Workers::Suppliers::Ciirus
  # +Workers::Suppliers::Ciirus::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = importer.fetch_properties(host)

      if result.success?
        properties = result.value
        properties.each do |property|
          property_id = property.property_id
          if validator(property).valid?
            permissions = fetch_permissions(property_id)
            next unless permissions.success?

            if permissions_validator(permissions.value).valid?
              synchronisation.start(property_id) do
                result = fetch_images(property_id)
                next result unless result.success?
                images = result.value

                result = fetch_description(property_id)
                next result unless result.success?
                description = result.value

                result = fetch_rates(property_id)
                next result unless result.success?
                rates = filter_rates(result.value)

                next empty_rates_error(property_id) if rates.empty?

                result = fetch_security_deposit(property_id)
                security_deposit = result.success? ? result.value : nil

                roomorama_property = mapper.build(property, images, rates, description, security_deposit)
                Result.new(roomorama_property)
              end
            else
              synchronisation.skip_property
            end
          else
            synchronisation.skip_property
          end
        end
        synchronisation.finish!
      else
        synchronisation.failed!
        message = 'Failed to perform the `#fetch_properties` operation'
        announce_error(message, result)
      end
    end

    private

    def empty_rates_error(property_id)
      message = "After filtering actual rates for property `#{property_id}` we got empty rates. " \
        "Sync property with empty rates doesn't make sense."
      augment_context_error(message)
      Result.error(:empty_rates_error)
    end

    def rate_validator(rate, today)
      Ciirus::Validators::RateValidator.new(rate, today)
    end

    def filter_rates(rates)
      today = Date.today
      rates.select { |r| rate_validator(r, today).valid? }
    end

    def report_error(message)
      yield.tap do |result|
        augment_context_error(message) unless result.success?
      end
    end

    def fetch_images(property_id)
      report_error("Failed to fetch images for property `#{property_id}`") do
        importer.fetch_images(property_id)
      end
    end

    def fetch_description(property_id)
      report_error("Failed to fetch description for property `#{property_id}`") do
        importer.fetch_description(property_id)
      end
    end

    def fetch_rates(property_id)
      report_error("Failed to fetch rates for property `#{property_id}`") do
        importer.fetch_rates(property_id)
      end
    end

    def fetch_permissions(property_id)
      importer.fetch_permissions(property_id).tap do |result|
        message = "Failed to fetch permissions for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_security_deposit(property_id)
      message = "Failed to fetch security deposit info for property `#{property_id}`. " \
            "But continue to sync the property as well as security deposit is optional information."
      report_error(message) do
        importer.fetch_security_deposit(property_id)
      end
    end

    def mapper
      @mapper ||= ::Ciirus::Mappers::RoomoramaProperty.new
    end

    def importer
      @importer ||= ::Ciirus::Importer.new(credentials)
    end

    def validator(property)
      Ciirus::Validators::PropertyValidator.new(property)
    end


    def permissions_validator(permissions)
      Ciirus::Validators::PermissionsValidator.new(permissions)
    end

    def credentials
      Concierge::Credentials.for(Ciirus::Client::SUPPLIER_NAME)
    end

    def augment_context_error(message)
      message = {
        label: 'Synchronisation Failure',
        message: message,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
    end

    def announce_error(message, result)
      augment_context_error(message)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    Ciirus::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.Ciirus') do |host|
  Workers::Suppliers::Ciirus::Metadata.new(host).perform
end
