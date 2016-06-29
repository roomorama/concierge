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
      # Calls the SAW API method usung the HTTP client.
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the resulting array of +SAW::Entities::Country+ objects.
      def call
        payload = payload_builder.build_countries_request
        result = http.post(endpoint(:countries), payload, content_type)
        
        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            countries = build_countries(result_hash)
            Result.new(countries)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      private
      def build_countries(countries_hash)
        countries = countries_hash.get("response.countries")
      
        return [] unless countries
        
        to_array(countries.get("country")).map do |hash|
          safe_hash = Concierge::SafeAccessHash.new(hash)
          SAW::Mappers::Country.build(safe_hash)
        end
      end

      def to_array(something)
        if something.is_a? Hash
          [something]
        else
          Array(something)
        end
      end
    end
  end
end
