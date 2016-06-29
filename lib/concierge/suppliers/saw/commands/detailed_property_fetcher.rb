module SAW
  module Commands
    # +SAW::Commands::DetailedPropertyFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # detailed versions of properties from SAW, parsing the response, and
    # building the +Result+ object
    #
    # Usage
    #
    #   command = SAW::Commands::DetailedProperty.new(credentials)
    #   result = command.call(country_id)
    class DetailedPropertyFetcher < BaseFetcher
      # Calls the SAW API method usung the HTTP client.
      #
      # Arguments
      # 
      #   * +property_id+ [String] id of the property to fetch
      #
      # The +call+ method returns a +Result+ object that, when successful,
      # encapsulates the array of resulting +SAW::Entities::DetailedProperty+
      # objects.
      def call(property_id)
        payload = payload_builder.propertydetail_request(property_id)
        result = http.post(endpoint(:property_detail), payload, content_type)

        if result.success?
          result_hash = response_parser.to_hash(result.value.body)

          if valid_result?(result_hash)
            property = build_property(result_hash)
            Result.new(property)
          else
            error_result(result_hash) 
          end
        else
          result
        end
      end

      private
      def build_property(result_hash)
        property_hash = result_hash.get("response.property")
      
        SAW::Mappers::DetailedProperty.build(
          property_hash,
          image_url_rewrite: credentials.url_rewrite
        )
      end

      def require_image_url_rewrite?
        credentials.url.start_with?('http://staging')
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
