module Workers::Suppliers::Avantio
  # +Workers::Suppliers::Avantio::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context do
        importer.fetch_properties
      end

      if result.success?
        properties = result.value
        properties.each do |property|
          property_id = property.property_id
          if validator(property).valid?
            permissions = synchronisation.new_context(property_id) do
              fetch_permissions(property_id)
            end
            next unless permissions.success?

            # Rates are needed for a property. Skip (and purge) properties that
            # has no rates or has error when retrieving rates.
            result = fetch_rates(property_id)
            next unless result.success?

            rates  = filter_rates(result.value)
            if rates.empty?
              synchronisation.skip_property
              next
            end

            if permissions_validator(permissions.value).valid?
              synchronisation.start(property_id) do
                result = fetch_images(property_id)
                next result unless result.success?
                images = result.value

                result = fetch_description(property_id)
                next result unless result.success?
                description = result.value

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
      importer.fetch_rates(property_id).tap do |result|
        unless result.success?
          if ignorable(result.error)
            synchronisation.skip_property
          else
            message = "Failed to fetch rates for property `#{property_id}`"
            announce_error(message, result)
          end
        end
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

    # Args:
    #   error: a Result#error
    #
    def ignorable(error)
      return IGNORABLE_ERROR_MESSAGES.any? { |err_msg|
        error.data&.include? err_msg
      }
    end

    def mapper
      @mapper ||= ::Avantio::Mappers::RoomoramaProperty.new
    end

    def importer
      @importer ||= ::Avantio::Importer.new(credentials)
    end

    def validator(property)
      Ciirus::Validators::PropertyValidator.new(property)
    end


    def permissions_validator(permissions)
      Ciirus::Validators::PermissionsValidator.new(permissions)
    end

    def credentials
      Concierge::Credentials.for(Avantio::Client::SUPPLIER_NAME)
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
        supplier:    Avantio::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.Avantio') do |host|
  Workers::Suppliers::Avantio::Metadata.new(host).perform
end
