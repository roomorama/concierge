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

    # Prevent from publishing property results containing error codes below.
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
      result = property_sync.new_context { fetch_owner(host.identifier) }
      return unless result.success?
      owner = result.value

      result = fetch_properties_collection_for_owner(owner.id)
      return unless result.success?
      properties_collection = result.value

      result = fetch_locations(properties_collection.location_ids)
      return unless result.success?
      locations = result.value

      result = fetch_location_currencies
      return unless result.success?
      currencies = result.value

      properties_collection.each_entry do |property_id, location_id|
        location = locations.find { |l| l.id == location_id }

        unless location
          message = "Failed to find location with id `#{location_id}`"
          announce_context_error(message, Result.error(:location_not_found))
          next
        end

        location.currency = currencies[location.id]

        unless location.currency
          message = "Failed to find currency for location with id `#{location_id}`"
          announce_context_error(message, Result.error(:currency_not_found))
          next
        end

        property_result = property_sync.new_context { fetch_property(property_id) }
        next unless property_result.success?
        property = property_result.value

        seasons_result = fetch_seasons(property_id)
        next unless seasons_result.success?
        seasons = seasons_result.value

        result = build_roomorama_property(property, location, owner, seasons)

        unless skip?(result, property)
          property_sync.start(property_id) { result } if result.success?
        end

        if synced_property?(property_id)
          sync_calendar(property_id, seasons)
        end
      end

      property_sync.finish!
    end

    private
    # Performs calendar (availabilities + seasons) synchronisation for
    # given property_id.
    def sync_calendar(property_id, seasons)
      calendar_sync.start(property_id) do
        result = fetch_availabilities(property_id)
        next result unless result.success?
        availabilities = result.value

        mapper = ::RentalsUnited::Mappers::Calendar.new(
          property_id,
          seasons,
          availabilities
        )
        mapper.build_calendar
      end

      calendar_sync.finish!
    end

    # Checks whether property exists in database or not.
    # Even if property was not synced in current synchronisation process, it's
    # possible that it was synced before.
    #
    # Performs query every time without caching identifiers.
    #
    # We can't cache identifiers because calendar sync should be started right
    # after each property sync and not when sync of all properties finished.
    #
    # (Otherwise we'll lose some data fetched inside the first sync process and
    # then we'll need to cache all data in memory so then we can reuse it)
    #
    # We can switch to the different strategy if memory usage will not be high
    # and we'll need to save database queries.
    def synced_property?(property_id)
      PropertyRepository.from_host(host).identified_by(property_id).count > 0
    end

    def importer
      @properties ||= ::RentalsUnited::Importer.new(credentials)
    end

    def credentials
      @credentials ||= Concierge::Credentials.for(
        ::RentalsUnited::Client::SUPPLIER_NAME
      )
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

    def fetch_owner(owner_id)
      sync_failed do
        announce_error("Failed to fetch owner with owner_id `#{owner_id}`") do
          importer.fetch_owner(owner_id)
        end
      end
    end

    def fetch_properties_collection_for_owner(owner_id)
      sync_failed do
        announce_error("Failed to fetch property ids collection for owner `#{owner_id}`") do
          importer.fetch_properties_collection_for_owner(owner_id)
        end
      end
    end

    def fetch_locations(location_ids)
      sync_failed do
        announce_error("Failed to fetch locations with ids `#{location_ids}`") do
          importer.fetch_locations(location_ids)
        end
      end
    end

    def fetch_location_currencies
      sync_failed do
        announce_error("Failed to fetch locations-currencies mapping") do
          importer.fetch_location_currencies
        end
      end
    end

    def fetch_property(property_id)
      sync_failed do
        message = "Failed to fetch property with property_id `#{property_id}`"
        announce_error(message) do
          importer.fetch_property(property_id)
        end
      end
    end

    def fetch_seasons(property_id)
      sync_failed do
        report_error("Failed to fetch seasons for property `#{property_id}`") do
          importer.fetch_seasons(property_id)
        end
      end
    end

    def fetch_availabilities(property_id)
      report_error("Failed to fetch availabilities for property `#{property_id}`") do
        importer.fetch_availabilities(property_id)
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

    def sync_failed
      yield.tap do |result|
        property_sync.failed! unless result.success?
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
