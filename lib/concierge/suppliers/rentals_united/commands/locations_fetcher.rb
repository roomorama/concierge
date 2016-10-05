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

      def initialize(credentials, location_ids)
        super(credentials)
        @location_ids = location_ids
      end

      # Retrieves locations by location_ids
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Location+ objects
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_locations
        payload = payload_builder.build_locations_fetch_payload
        result = api_call(payload)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          raw_locations = build_raw_locations(result_hash)

          locations = location_ids.map do |id|
            location = build_location(id, raw_locations)

            return Result.error(:unknown_location) unless location

            location
          end

          Result.new(locations)
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
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
    end
  end
end
