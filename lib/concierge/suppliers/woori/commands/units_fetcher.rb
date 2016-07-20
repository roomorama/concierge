module Woori
  module Commands
    # +Woori::Commands::CountryUnitsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # property units from Woori, parsing the response, and building the
    # +Result+ object
    #
    # Usage
    #
    #   command = Woori::Commands::UnitsFetcher.new(credentials)
    #   result = command.call("w_w0104006")
    class UnitsFetcher < BaseFetcher
      include Concierge::JSON
    
      ENDPOINT = "properties/:property_id/roomtypes"

      def call(property_id)
        params = build_request_params
        path = build_path(property_id)
        result = http.get(path, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)
          
          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            units = build_units(safe_hash)
            Result.new(units)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params
        { i18n: 'en-US' }
      end

      def build_path(property_id)
        ENDPOINT.gsub(":property_id", property_id)
      end

      def build_units(hash)
        units = hash.get("data.items")

        Array(units).map do |unit_hash|
          safe_hash = Concierge::SafeAccessHash.new(unit_hash)
          Woori::Mappers::RoomoramaUnit.build(safe_hash)
        end
      end
    end
  end
end
