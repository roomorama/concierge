module SAW
  module Commands
    # +SAW::Commands::CountryPropertiesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # properties from SAW, parsing the response, and building the +Result+ 
    # object
    #
    # Usage
    #
    #   command = SAW::Commands::CountryPropertiesFetcher.new(credentials)
    #   result = command.call(country)
    class CountryPropertiesFetcher < BaseFetcher
      # Calls the SAW API method usung the HTTP client.
      #
      # Arguments
      # 
      #   * +country+ [SAW:Entities::Country] country to return properties from
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the array of resulting +SAW::Entities::BasicProperty+
      # objects.
      def call(country)
        payload = payload_builder.propertysearch_request(country: country.id)
        result = http.post(endpoint(:property_search), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            properties = build_properties(result_hash, country)
            Result.new(properties)
          else
            error_result(result_hash) 
          end
        else
          result
        end
      end

      private
      def build_properties(properties_hash, country)
        properties = properties_hash.get("response.properties.property")

        if properties
          to_array(properties).map do |prop|
            SAW::Mappers::BasicProperty.build(prop, country: country.name)
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
