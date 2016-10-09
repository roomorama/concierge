module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::LocationsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # locations from RentalsUnited, parsing the response, and building
    # +Result+ object.
    class LocationsFetcher < BaseFetcher
      attr_reader :location_ids

      ROOT_TAG = "Pull_ListLocations_RS"

      CACHE_PREFIX   = "rentalsunited"
      CACHE_KEY      = "locations"
      CACHE_DURATION = 7 * 24 * 60 * 60 # one week

      def initialize(credentials, location_ids)
        super(credentials)
        @location_ids = location_ids
      end

      # Retrieves locations by location_ids
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Location+ objects
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_locations
        locations_result = fetch_locations_static_data
        return locations_result unless locations_result.success?
        locations_hash = response_parser.to_hash(locations_result.value)

        raw_locations = build_raw_locations(locations_hash)

        requested_locations = location_ids.map do |id|
          location = build_location(id, raw_locations)

          return unknown_location_error(id) unless location

          location
        end

        Result.new(requested_locations)
      end

      private
      # Caches successful locations API response
      def fetch_locations_static_data
        with_cache(CACHE_KEY, freshness: CACHE_DURATION) do
          payload = payload_builder.build_locations_fetch_payload
          result = api_call(payload)

          return result unless result.success?

          result_hash = response_parser.to_hash(result.value.body)

          if valid_status?(result_hash, ROOT_TAG)
            Result.new(result.value.body)
          else
            error_result(result_hash, ROOT_TAG)
          end
        end
      end

      def build_raw_locations(hash)
        locations = hash.get("Pull_ListLocations_RS.Locations.Location")

        Array(locations).map do |l|
          {
            id: l.attributes["LocationID"],
            name: l.to_s,
            type: l.attributes["LocationTypeID"].to_i,
            parent_id: l.attributes["ParentLocationID"]
          }
        end
      end

      def build_location(location_id, raw_locations)
        mapper = Mappers::Location.new(location_id, raw_locations)
        mapper.build_location
      end

      def with_cache(key, freshness:)
        cache.fetch(key, freshness: freshness) { yield }
      end

      def cache
        @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
      end

      def unknown_location_error(location_id)
        message = "Unknown location with id `#{location_id}`"
        Result.error(:unknown_location, message)
      end
    end
  end
end
