module Woori
  module Commands
    # +Woori::Commands::CountryPropertiesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # properties from Woori, parsing the response, and building the +Result+ 
    # object
    #
    # Usage
    #
    #   command = Woori::Commands::PropertiesFetcher.new(credentials)
    #   result = command.call(updated_at, limit, offset)
    class PropertiesFetcher < BaseFetcher
      include Concierge::JSON
      
      ENDPOINT = "properties"

      def call(updated_at, limit, offset)
        params = build_request_params(updated_at, limit, offset)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)
          
          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            properties = build_properties(safe_hash)
            Result.new(properties)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params(updated_at, limit, offset)
        {
          updatedAt: updated_at,
          limit: limit,
          offset: offset,
          active: 1,
          i18n: 'en-US'
        }
      end

      def build_properties(hash)
        properties = hash.get("data.items")

        if properties
          properties.map do |propery_hash|
            safe_hash = Concierge::SafeAccessHash.new(propery_hash)
            Woori::Mappers::RoomoramaProperty.build(safe_hash)
          end
        else
          []
        end
      end
    end
  end
end
