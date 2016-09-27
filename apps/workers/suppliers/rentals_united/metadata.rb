module Workers::Suppliers::RentalsUnited
  # +Workers::Suppliers::RentalsUnited+
  #
  # Performs property & calendar synchronisation with supplier.
  #
  # Decision to merge two workers in one was made because of the prices
  # issue when we needed to fetch prices with the same API calls in both
  # metadata and calendar sync workers.
  #
  # See more in corresponding PR discussion:
  #   https://github.com/roomorama/concierge/pull/309#pullrequestreview-682041
  class Metadata
    attr_reader :property_sync, :calendar_sync, :host

    # Prevent from publishing results containing error codes below:
    IGNORABLE_ERROR_CODES = [
      :empty_seasons,
      :attempt_to_build_archived_property,
      :attempt_to_build_not_active_property,
      :security_deposit_not_supported,
      :property_type_not_supported
    ]

    def initialize(host)
      @host = host
      @property_sync = Workers::PropertySynchronisation.new(host)
      @calendar_sync = Workers::CalendarSynchronisation.new(host)
    end

    def perform
      result = property_sync.new_context { fetch_location_ids }
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
          result = property_sync.new_context { fetch_property_ids(location.id) }
          next unless result.success?

          property_ids = result.value

          result = fetch_properties_by_ids(property_ids, location)
          next unless result.success?

          sync_properties(result.value, location, owners)
        else
          message = "Failed to find currency for location with id `#{location.id}`"
          announce_context_error(message, Result.error(:currency_not_found))
          next
        end
      end
      property_sync.finish!
    end

    def sync_properties(properties, location, owners)
      properties.each do |property|
        owner = find_owner(owners, property.owner_id)

        if owner
          result = fetch_seasons(property.id)
          next result unless result.success?
          seasons = result.value

          result = build_roomorama_property(property, location, owner, seasons)
          next if skip?(result, property)

          property_sync.start(property.id) do
            result
          end
        else
          message = "Failed to find owner for property id `#{property.id}`"
          announce_context_error(message, Result.error(:owner_not_found))
          next
        end
      end
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

    def build_roomorama_property(property, location, owner, seasons)
      mapper = ::RentalsUnited::Mappers::RoomoramaProperty.new(
        property,
        location,
        owner,
        seasons
      )
      mapper.build_roomorama_property
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
      announce_error("Failed to fetch property ids for location `#{location_id}`") do
        importer.fetch_property_ids(location_id)
      end
    end

    def fetch_properties_by_ids(property_ids, location)
      message = "Failed to fetch properties for ids `#{property_ids}` in location `#{location.id}`"
      announce_error(message) do
        importer.fetch_properties_by_ids(property_ids)
      end
    end

    def fetch_seasons(property_id)
      report_error("Failed to fetch seasons for property `#{property_id}`") do
        importer.fetch_seasons(property_id)
      end
    end

    def skip?(result, property)
      if !result.success? && IGNORABLE_ERROR_CODES.include?(result.error.code)
        property_sync.skip_property(property.id, result.error.code)
        return true
      end
      return false
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
