module SAW
  module Commands
    class CountriesFetcher < BaseFetcher
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
      
        if countries
          to_array(countries.get("country")).map do |hash|
            SAW::Mappers::Country.build(hash)
          end
        else
          []
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
