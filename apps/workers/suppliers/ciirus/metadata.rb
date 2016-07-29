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
      result = importer.fetch_properties

      if result.success?
        properties = result.value
        properties.each do |property|
          property_id = property.property_id
          if validator(property).valid?
            synchronisation.start(property_id) do
              Concierge.context.disable!

              result = fetch_permissions(property_id)
              next result unless result.success?
              permissions = result.value

              if permissions_validator(permissions).valid?
                result = fetch_images(property_id)
                next result unless result.success?
                images = result.value

                result = fetch_description(property_id)
                next result unless result.success?
                description = result.value

                result = fetch_rates(property_id)
                next result unless result.success?
                rates = result.value

                result = fetch_security_deposit(property_id)
                security_deposit = result.success? ? result.value : nil

                roomorama_property = mapper.build(property, images, rates, description, security_deposit)
                Result.new(roomorama_property)
              else
                invalid_permissions_error(permissions)
              end
            end
          end
        end
        synchronisation.finish!
      else
        synchronisation.failed!
        message = 'Failed to perform the `#fetch_properties` operation'
        announce_error(message, result)
      end
    end

    def invalid_permissions_error(permissions)
      with_context_enabled do
        message = "Invalid permissions for property `#{permissions.property_id}`. The property should be
                   online bookable and not timeshare: `#{permissions.to_h}`"
        augment_context_error(message)
      end
      Result.error(:invalid_permissions_error)
    end

    private

    def fetch_images(property_id)
      result = importer.fetch_images(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch images for property `#{property_id}`"
          augment_context_error(message)
        end
      end

      result
    end

    def fetch_description(property_id)
      result = importer.fetch_description(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch description for property `#{property_id}`"
          augment_context_error(message)
        end
      end

      result
    end

    def fetch_rates(property_id)
      result = importer.fetch_rates(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch rates for property `#{property_id}`"
          augment_context_error(message)
        end
      end

      result
    end

    def fetch_permissions(property_id)
      result = importer.fetch_permissions(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch permissions for property `#{property_id}`"
          augment_context_error(message)
        end
      end

      result
    end

    def fetch_security_deposit(property_id)
      result = importer.fetch_security_deposit(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch security deposit info for property `#{property_id}`
                     But continue to sync the property as well as security deposit
                     is optional information."
          augment_context_error(message)
        end
      end

      result
    end

    def with_context_enabled
      Concierge.context.enable!
      yield
      Concierge.context.disable!
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
