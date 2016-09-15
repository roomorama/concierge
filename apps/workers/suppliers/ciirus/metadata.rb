module Workers::Suppliers::Ciirus
  # +Workers::Suppliers::Ciirus::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host
    IGNORABLE_RATES_ERROR_MESSAGES = [
      "(soap:Server) Server was unable to process request. ---> GetPropertyRates: Error - No Rate Assigned by user. Please contact the user and request they populate this data.",
      "(soap:Server) Server was unable to process request. ---> GetPropertyRates: Error - No Rate Rows Returned"
    ]

    IGNORABLE_IMAGES_ERROR_MESSAGE = '(soap:Server) Server was unable to process request. ---> GetImageList: This property contains demo images.'

    def initialize(host)
      @host            = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context do
        importer.fetch_properties(host)
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

            unless permissions_validator(permissions.value).valid?
              synchronisation.skip_property
              next
            end

            # Rates are needed for a property. Skip (and purge) properties that
            # has no rates or has error when retrieving rates.
            result = fetch_rates(property_id)
            next unless result.success?

            rates  = filter_rates(result.value)
            if rates.empty?
              synchronisation.skip_property
              next
            end

            result = fetch_images(property_id)
            next unless result.success?
            images = result.value

            result = fetch_description(property_id)
            next unless result.success?
            description = result.value
            if description.to_s.empty?
              synchronisation.skip_property
              next
            end

            synchronisation.start(property_id) do

              result = fetch_security_deposit(property_id)
              security_deposit = result.success? ? result.value : nil

              roomorama_property = mapper.build(property, images, rates, description, security_deposit)
              Result.new(roomorama_property)
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
      importer.fetch_images(property_id).tap do |result|
        unless result.success?
          if ignorable_images_error?(result.error)
            synchronisation.skip_property
          else
            message = "Failed to fetch images for property `#{property_id}`"
            announce_error(message, result)
          end
        end
      end
    end

    def fetch_description(property_id)
      importer.fetch_description(property_id).tap do |result|
        message = "Failed to fetch description for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_rates(property_id)
      importer.fetch_rates(property_id).tap do |result|
        unless result.success?
          if ignorable_rates_error?(result.error)
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
    def ignorable_rates_error?(error)
      IGNORABLE_RATES_ERROR_MESSAGES.any? { |err_msg|
        error.data&.include? err_msg
      }
    end

    def ignorable_images_error?(error)
      error.data&.include? IGNORABLE_IMAGES_ERROR_MESSAGE
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
Concierge::Announcer.on('metadata.Ciirus') do |host, args|
  Workers::Suppliers::Ciirus::Metadata.new(host).perform
  Result.new({})
end
