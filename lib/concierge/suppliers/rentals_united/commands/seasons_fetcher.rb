module RentalsUnited
  module Commands
    # +RentalsUnited::Commands::SeasonsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property rate seasons from RentalsUnited
    class SeasonsFetcher < BaseFetcher
      attr_reader :property_id

      ROOT_TAG = "Pull_ListPropertyPrices_RS"
      YEARS_COUNT_TO_FETCH = 1

      CACHE_PREFIX   = "rentalsunited"
      CACHE_KEY_PREFIX = "seasons"
      CACHE_DURATION = 24 * 60 * 60 # 24 hours

      # Initialize +SeasonsFetcher+ command.
      #
      # Arguments
      #
      #   * +credentials+
      #   * +property_id+ [String]
      #
      # Usage:
      #
      #   RentalsUnited::Commands::SeasonsFetcher.new(
      #     credentials,
      #     property_id
      #   )
      def initialize(credentials, property_id)
        super(credentials)

        @property_id = property_id
      end

      # Retrieves property rate seasons.
      #
      # Returns a +Result+ wrapping +Array+ of +Entities::Season+ objects
      # Returns a +Result+ with +Result::Error+ when operation fails
      def fetch_seasons
        result = fetch_seasons_static_data
        return result unless result.success?

        result_hash = response_parser.to_hash(result.value)
        Result.new(build_seasons(result_hash))
      end

      private
      def cache_key
        "#{CACHE_KEY_PREFIX}-#{property_id}"
      end

      def with_cache(key, freshness:)
        cache.fetch(key, freshness: freshness) { yield }
      end

      def cache
        @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
      end

      def fetch_seasons_static_data
        with_cache(cache_key, freshness: CACHE_DURATION) do
          payload = payload_builder.build_seasons_fetch_payload(
            property_id,
            date_from,
            date_to
          )
          result = http.post(credentials.url, payload, headers)

          return result unless result.success?

          result_hash = response_parser.to_hash(result.value.body)

          if valid_status?(result_hash, ROOT_TAG)
            Result.new(result.value.body)
          else
            error_result(result_hash, ROOT_TAG)
          end
        end
      end

      def date_from
        Time.now.strftime("%Y-%m-%d")
      end

      def date_to
        current = Time.now

        year = current.year + YEARS_COUNT_TO_FETCH
        date = Time.new(year, current.month, current.day)
        date.strftime("%Y-%m-%d")
      end

      def build_seasons(hash)
        seasons = Array(hash.get("#{ROOT_TAG}.Prices.Season"))
        seasons.map do |season|
          mapper = Mappers::Season.new(season)
          mapper.build_season
        end
      end
    end
  end
end
