module Workers::Suppliers::Poplidays
  # +Workers::Suppliers::Poplidays::Metadata+
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
          if validator(property).valid?
            property_id = property['id']
            synchronisation.start(property_id) do
              Concierge.context.disable!

              result = fetch_property_details(property_id)
              next result unless result.success?
              details = result.value

              if details_validator(details).valid?
                result = fetch_availabilities(property_id)
                next result unless result.success?
                availabilities = result.value

                mapper.build(property, details, availabilities)
              else
                Result.error(:invalid_property_details_error)
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

    private

    def fetch_property_details(property_id)
      result = importer.fetch_property_details(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch details for property `#{property_id}`"
          augment_context_error(message)
        end
      end

      result
    end

    def fetch_availabilities(property_id)
      result = importer.fetch_availabilities(property_id)

      unless result.success?
        with_context_enabled do
          message = "Failed to fetch availabilities for property `#{property_id}`"
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
      @mapper ||= ::Poplidays::Mappers::RoomoramaProperty.new
    end

    def importer
      @importer ||= ::Poplidays::Importer.new(credentials)
    end

    def validator(property)
      Poplidays::Validators::PropertyValidator.new(property)
    end

    def details_validator(details)
      Poplidays::Validators::PropertyDetailsValidator.new(details)
    end

    def credentials
      Concierge::Credentials.for(Poplidays::Client::SUPPLIER_NAME)
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
        supplier:    Poplidays::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.Poplidays') do |host|
  Workers::Suppliers::Poplidays::Metadata.new(host).perform
end