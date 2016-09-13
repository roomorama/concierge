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
          if validator(property).valid?
            property_id = property['id']

            details = synchronisation.new_context { fetch_property_details(property_id) }
            next unless details.success?

            unless details_validator(details.value).valid?
              synchronisation.skip_property
              next
            end

            result = fetch_availabilities(property_id)
            next unless result.success?

            availabilities = filter_availabilities(result.value)

            if availabilities.empty?
              synchronisation.skip_property
              next
            end

            synchronisation.start(property_id) do
              Concierge.context.disable!

              result = fetch_extras(property_id)
              extras = result.value if result.success?

              mapper.build(property, details.value, availabilities, extras)
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

    def filter_availabilities(availabilities)
      today = Date.today

      availabilities['availabilities'].select do |availability|
        availability_validator(availability, today).valid?
      end
    end

    def report_error(message)
      yield.tap do |result|
        unless result.success?
          with_context_enabled { augment_context_error(message) }
        end
      end
    end

    def fetch_property_details(property_id)
      importer.fetch_property_details(property_id).tap do |result|
        message = "Failed to fetch details for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_availabilities(property_id)
      importer.fetch_availabilities(property_id).tap do |result|
        message = "Failed to fetch availabilities for property `#{property_id}`"
        announce_error(message, result) unless result.success?
      end
    end

    def fetch_extras(property_id)
      message = "Failed to fetch extras info for property `#{property_id}`. " \
            "But continue to sync the property as well as extras is optional information."
      report_error(message) do
        importer.fetch_extras(property_id)
      end
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

    def availability_validator(details, today)
      Poplidays::Validators::AvailabilityValidator.new(details, today)
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