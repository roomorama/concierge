module Workers::Suppliers::RentalsUnited
  # +Workers::Suppliers::RentalsUnited+
  #
  # Performs synchronisation with supplier
  class Metadata
    attr_reader :synchronisation, :host

    def initialize(host)
      @host = host
      @synchronisation = Workers::PropertySynchronisation.new(host)
    end

    def perform
      result = synchronisation.new_context { fetch_location_ids }
      return unless result.success?

      location_ids = result.value

      result = fetch_locations(location_ids)
      return unless result.success?

      locations = result.value

      result = fetch_location_currencies
      return unless result.success?

      currencies = result.value

      result = fetch_owners
      return unless result.success?

      owners = result.value

      locations.each do |location|
        location.currency = currencies[location.id]

        if location.currency
          result = synchronisation.new_context { fetch_property_ids(location.id) }
          return unless result.success?

          property_ids = result.value

          result = fetch_properties_by_ids(property_ids)

          if result.success?
            properties = result.value

            properties.each do |property|
              owner = find_owner(owners, property.owner_id)

              if owner
                synchronisation.start(property.id) do
                  mapper = ::RentalsUnited::Mappers::RoomoramaProperty.new(
                    property,
                    location,
                    owner
                  )
                  mapper.build_roomorama_property
                end
              else
                message = "Failed to find owner for property id `#{property.id}`"
                announce_context_error(message, result)
                next
              end
            end
          else
            message = "Failed to fetch properties for ids `#{property_ids}` in location `#{location.id}`"
            announce_context_error(message, result)
            next
          end
        else
          message = "Failed to find currency for location with id `#{location.id}`"
          announce_context_error(message, result)
          next
        end
      end

      synchronisation.finish!
    end

    private

    def importer
      @properties ||= ::RentalsUnited::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for(
        ::RentalsUnited::Client::SUPPLIER_NAME
      )
    end

    def find_owner(owners, owner_id)
      owners.find { |o| o.id == owner_id }
    end

    def fetch_location_ids
      announce_error("Failed to fetch location ids") do
        importer.fetch_location_ids
      end
    end

    def fetch_locations(location_ids)
      announce_error("Failed to fetch locations") do
        importer.fetch_locations(location_ids)
      end
    end

    def fetch_location_currencies
      announce_error("Failed to fetch locations-currencies mapping") do
        importer.fetch_location_currencies
      end
    end

    def fetch_owners
      announce_error("Failed to fetch owners") do
        importer.fetch_owners
      end
    end

    def fetch_property_ids(location_id)
      announce_error("Failed to fetch properties for location `#{location_id}`") do
        importer.fetch_property_ids(location_id)
      end
    end

    def fetch_properties_by_ids(property_ids)
      announce_error("Failed to fetch properties by ids `#{property_ids}`") do
        importer.fetch_properties_by_ids(property_ids)
      end
    end

    def announce_error(message)
      yield.tap do |result|
        announce_context_error(message, result) unless result.success?
      end
    end

    def report_error(message)
      yield.tap do |result|
        augment_context_error(message) unless result.success?
      end
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

    def announce_context_error(message, result)
      augment_context_error(message)

      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   'sync',
        supplier:    RentalsUnited::Client::SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end
end

Concierge::Announcer.on("metadata.RentalsUnited") do |host, args|
  Workers::Suppliers::RentalsUnited::Metadata.new(host).perform
  Result.new({})
end
