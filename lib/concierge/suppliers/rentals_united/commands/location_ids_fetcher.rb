module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::LocationIdsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # location ids from RentalsUnited
    class LocationIdsFetcher < BaseFetcher
      attr_reader :location

      ROOT_TAG = "Pull_ListCitiesProps_RS"

      # Retrieves location ids with active properties.
      #
      # Locations without active properties are ignored.
      def fetch_location_ids
        payload = payload_builder.build_location_ids_fetch_payload
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(parse_location_ids(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def parse_location_ids(hash)
        locations = hash.get("#{ROOT_TAG}.CitiesProps.CityProps")

        Array(locations).map { |location| location.attributes["LocationID"] }
      end
    end
  end
end
