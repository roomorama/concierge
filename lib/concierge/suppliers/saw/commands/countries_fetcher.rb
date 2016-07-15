module SAW
  module Commands
    # +SAW::Commands::CountriesFetcher+
    #
    # This class is responsible for fetching list of countries from the SAW API
    #
    # Usage
    #
    #   command = SAW::Commands::CountriesFetcher.new(credentials)
    #   result = command.call
    #
    #   if result.success?
    #     countries = result.value
    #   else
    #     handle_error(result.error)
    #   end
    class CountriesFetcher < BaseFetcher
      CACHE_PREFIX   = "saw"
      CACHE_KEY      = "countries"
      CACHE_DURATION = 7 * 24 * 60 * 60 # one week

      # Calls the SAW API method usung the HTTP client.
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the resulting array of +SAW::Entities::Country+ objects.
      def call
        raw_countries = with_cache(CACHE_KEY, freshness: CACHE_DURATION) do
          payload = payload_builder.build_countries_request
          result = http.post(endpoint(:countries), payload, content_type)

          if result.success?
            Result.new(result.value.body)
          else
            return result
          end
        end

        countries_hash = response_parser.to_hash(raw_countries.value)

        if valid_result?(countries_hash)
          countries = build_countries(countries_hash)
          Result.new(countries)
        else
          error_result(countries_hash)
        end
      end

      private
      def build_countries(countries_hash)
        countries = countries_hash.get("response.countries")
      
        return [] unless countries
        
        Array(countries.get("country")).map do |hash|
          safe_hash = Concierge::SafeAccessHash.new(hash)
          SAW::Mappers::Country.build(safe_hash)
        end
      end
      
      def with_cache(key, freshness:)
        cache.fetch(key, freshness: freshness) { yield }
      end

      def cache
        @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
      end
    end
  end
end
