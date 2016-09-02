module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::CitiesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # cities from RentalsUnited, parsing the response, and building
    # +Result+ object.
    class CitiesFetcher < BaseFetcher
      attr_reader :location

      ROOT_TAG = "Pull_ListCitiesProps_RS"

      # Retrieves cities with active properties.
      #
      # Cities without active properties are ignored.
      def fetch_cities
        payload = payload_builder.build_cities_fetch_payload
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_cities(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_cities(hash)
        cities = hash.get("#{ROOT_TAG}.CitiesProps.CityProps")
        return [] unless cities

        Array(cities).map do |city|
          mapper = RentalsUnited::Mappers::City.new(city)
          mapper.build
        end
      end
    end
  end
end
