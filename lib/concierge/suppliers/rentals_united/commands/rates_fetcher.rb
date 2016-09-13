module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::RatesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property rates from RentalsUnited
    class RatesFetcher < BaseFetcher
      attr_reader :property_id

      ROOT_TAG = "Pull_ListPropertyPrices_RS"
      YEARS_COUNT_TO_FETCH = 1

      # Initialize +RatesFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +property_id+ [String]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::RatesFetcher.new(
      #     credentials,
      #     property_id
      #   )
      def initialize(credentials, property_id)
        super(credentials)

        @property_id = property_id
      end

      # Retrieves property rates.
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Rate+ objects
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_rates
        payload = payload_builder.build_rates_fetch_payload(
          property_id,
          date_from,
          date_to
        )
        result = http.post(credentials.url, payload, headers)

        return result unless result.success?

        result_hash = response_parser.to_hash(result.value.body)

        if valid_status?(result_hash, ROOT_TAG)
          Result.new(build_rates(result_hash))
        else
          error_result(result_hash, ROOT_TAG)
        end
      end

      private
      def date_from
        Time.now.strftime("%Y-%m-%d")
      end

      def date_to
        current = Time.now

        year = current.year + YEARS_COUNT_TO_FETCH
        date = Time.new(year, current.month, current.day)
        date.strftime("%Y-%m-%d")
      end

      def build_rates(hash)
        seasons = Array(hash.get("#{ROOT_TAG}.Prices.Season"))
        seasons.map do |season|
          mapper = Mappers::Rate.new(season)
          mapper.build_rate
        end
      end
    end
  end
end
