module Workers::Suppliers::Ciirus
  # +Workers::Suppliers::Ciirus::Metadata+
  #
  # Performs properties synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host
    IGNORABLE_RATES_ERROR_MESSAGES = [
      "(soap:Server) Server was unable to process request. ---> GetPropertyRates: Error - No Rate Assigned by user. Please contact the user and request they populate this data.",
      "(soap:Server) Server was unable to process request. ---> GetPropertyRates: Error - No Rate Rows Returned",
      "(soap:Server) Server was unable to process request. ---> GetPropertyRates: Monthly Rates Not Supported via API. Monthly Rates Set By User. Please contact the Unit Supplier to configure a supported rate type for your channel."
    ]

    IGNORABLE_IMAGES_ERROR_MESSAGES = [
      '(soap:Server) Server was unable to process request. ---> GetImageList: This property contains demo images.',
      '(soap:Server) Server was unable to process request. ---> GetImageList: Error - No Images exist for this property at this time. Please contact the user and request they populate this data.'
    ]

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
            synchronisation.start(property_id) do
              # Puts property info to context for analyze in case of error
              augment_property_info(property)

              permissions = fetch_permissions(property_id)
              next permissions unless permissions.success?

              unless permissions_validator(permissions.value).valid?
                next synchronisation.skip_property(property_id, 'Invalid permissions')
              end

              # Rates are needed for a property. Skip (and purge) properties that
              # has no rates or has error when retrieving rates.
              result = fetch_rates(property_id)
              next result unless result.success?

              rates  = filter_rates(result.value)
              next synchronisation.skip_property(property_id, 'Empty valid rates list') if rates.empty?

              result = fetch_images(property_id)
              next result unless result.success?
              images = result.value

              result = fetch_description(property_id)
              next result unless result.success?

              description = result.value
              if description.to_s.empty?
                next synchronisation.skip_property(property_id, 'Empty description')
              end

              result = fetch_security_deposit(property_id)
              security_deposit = result.success? ? result.value : nil

              roomorama_property = mapper.build(property, images, rates, description, security_deposit)
              Result.new(roomorama_property)
            end
          else
            synchronisation.skip_property(property_id, 'Invalid property')
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
            synchronisation.skip_property(property_id, "Ignorable images error: #{result.error.data}")
          else
            message = "Failed to fetch images for property `#{property_id}`"
            augment_context_error(message)
          end
        end
      end
    end

    def fetch_description(property_id)
      message = "Failed to fetch description for property `#{property_id}`"
      report_error(message) do
        importer.fetch_description(property_id)
      end
    end

    def fetch_rates(property_id)
      importer.fetch_rates(property_id).tap do |result|
        unless result.success?
          if ignorable_rates_error?(result.error)
            synchronisation.skip_property(property_id, "Ignorable rates error: #{result.error.data}")
          else
            message = "Failed to fetch rates for property `#{property_id}`"
            augment_context_error(message)
          end
        end
      end
    end

    def fetch_permissions(property_id)
      message = "Failed to fetch permissions for property `#{property_id}`"
      report_error(message) do
        importer.fetch_permissions(property_id)
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
      IGNORABLE_IMAGES_ERROR_MESSAGES.any? { |err_msg|
        error.data&.include? err_msg
      }
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

    def augment_property_info(property)
      message = {
        label: 'Property Info',
        message: property.to_s,
        backtrace: caller
      }
      context = Concierge::Context::Message.new(message)
      Concierge.context.augment(context)
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
        description: result.error.data,
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
