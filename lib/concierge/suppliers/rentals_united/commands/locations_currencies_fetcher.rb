module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::LocationCurrenciesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # location currencies from RentalsUnited
    class LocationCurrenciesFetcher < BaseFetcher
      ROOT_TAG = "Pull_ListCurrenciesWithCities_RS"

      # Retrieves locations - currencies mapping.
      #
      # Returns a +Result+ wrapping +Hash+ with location_id => currency pairs
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_location_currencies
        payload = payload_builder.build_location_currencies_fetch_payload
        result = api_call(payload)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          location_currencies = build_location_currencies(result_hash)
          Result.new(location_currencies)
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def build_location_currencies(result_hash)
        location_currencies = {}

        currencies_hash = result_hash.get("#{ROOT_TAG}.Currencies.Currency")
        currencies_hash.each do |currency_hash|
          safe_hash = Concierge::SafeAccessHash.new(currency_hash)
          location_ids = Array(safe_hash.get("Locations.LocationID"))
          currency_code = safe_hash.get("@CurrencyCode")

          location_ids.each do |location_id|
            location_currencies[location_id] = currency_code
          end
        end

        location_currencies
      end
    end
  end
end
