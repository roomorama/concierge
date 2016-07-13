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
    #   result = command.call(country)
    class PropertiesFetcher < BaseFetcher
      include Concierge::JSON

      def call
        params = build_request_params
        result = http.get(endpoint(:properties), params, headers)

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
      def build_request_params
        {
          updatedAt: '1970-01-01',
          limit: 5,
          offset: 0,
          active: 1
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
