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
      result = synchronisation.new_context { importer.fetch_properties }

      if result.success?
        properties = result.value
        properties.each do |property|
          property_id = property['id']
          if validator(property).valid?
            synchronisation.start(property_id) do
              details = fetch_property_details(property_id)
              next details unless details.success?

              unless details_validator(details.value).valid?
                next synchronisation.skip_property(property_id, 'Invalid property details')
              end

              result = importer.fetch_availabilities(property_id)
              next result unless result.success?

              availabilities = filter_availabilities(result.value)

              if availabilities.empty?
                next synchronisation.skip_property(property_id, 'Empty valid availabilities list')
              end

              result = fetch_extras(property_id)
              extras = result.value if result.success?

              mapper.build(property, details.value, availabilities, extras)
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

    def filter_availabilities(availabilities)
      Array(availabilities['availabilities']).select do |availability|
        availability_validator(availability).valid?
      end
    end

    def fetch_property_details(property_id)
      importer.fetch_property_details(property_id).tap do |result|
        message = "Failed to fetch details for property `#{property_id}`"
        augment_context_error(message) unless result.success?
      end
    end

    def fetch_availabilities(property_id)
      importer.fetch_availabilities(property_id).tap do |result|
        message = "Failed to fetch availabilities for property `#{property_id}`"
        augment_context_error(message) unless result.success?
      end
    end

    def fetch_extras(property_id)
      importer.fetch_extras(property_id).tap do |result|
        message = "Failed to fetch extras info for property `#{property_id}`. " \
          "But continue to sync the property as well as extras is optional information."
        augment_context_error(message) unless result.success?
      end
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

    def availability_validator(details)
      Poplidays::Validators::AvailabilityValidator.new(details)
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
        description: result.error.data,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

# listen supplier worker
Concierge::Announcer.on('metadata.Poplidays') do |host, args|
  Workers::Suppliers::Poplidays::Metadata.new(host).perform
  Result.new({})
end
