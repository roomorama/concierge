module SAW
  module Commands
    class DetailedPropertyFetcher < BaseFetcher
      def call(property_id)
        payload = payload_builder.propertydetail_request(property_id)
        result = http.post(endpoint(:propertydetail), payload, content_type)

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
        property_hash = result_hash["response"]["property"]
      
        SAW::Mappers::DetailedProperty.build(
          property_hash,
          image_url_rewrite: require_image_url_rewrite?
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
