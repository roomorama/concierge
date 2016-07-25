module Woori
  module Commands
    # +Woori::Commands::UnitsFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # property units from Woori, parsing the response, and building the
    # +Result+ object
    class UnitsFetcher < BaseFetcher
      include Concierge::JSON
    
      ENDPOINT = "properties/:property_id/roomtypes"

      # Retrieves the list of units for property by its id
      #
      # Arguments
      #
      #   * +property_id+ [String] property id (property hash in Woori API)
      #
      # Usage
      #
      #   command = Woori::Commands::UnitsFetcher.new(credentials)
      #   result = command.call("w_w0104006")
      #
      # Returns a +Result+ wrapping an +Array+ of +Roomorama::Unit+ objects
      # when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
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
        { i18n: default_locale }
      end

      def build_path(property_id)
        ENDPOINT.gsub(":property_id", property_id)
      end

      def build_units(hash)
        units = hash.get("data.items")

        Array(units).map do |unit_hash|
          safe_hash = Concierge::SafeAccessHash.new(unit_hash)
          mapper = Woori::Mappers::RoomoramaUnit.new(safe_hash)
          mapper.build_unit
        end
      end
    end
  end
end
