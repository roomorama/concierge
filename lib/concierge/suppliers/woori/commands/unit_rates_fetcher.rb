module Woori
  module Commands
    # +Woori::Commands::UnitRatesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching 
    # unit rates from Woori, parsing the response, and building the
    # +Result+ object
    #
    # Usage
    #
    #   command = Woori::Commands::UnitRatesFetcher.new(credentials)
    #   result = command.call("w_w0104006")
    class UnitRatesFetcher < BaseFetcher
      include Concierge::JSON
    
      ENDPOINT = "available"

      def call(unit_id)
        params = build_request_params(unit_id)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)
          
          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            mapper = Woori::Mappers::UnitRates.new(safe_hash)
            unit_rates = mapper.build
            Result.new(unit_rates)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params(unit_id)
        current_date = Time.now

        {
          roomCode: unit_id,
          searchStartDate: current_date.strftime("%Y-%m-%d"),
          searchEndDate: (current_date + 30 * 60 * 60 * 24).strftime("%Y-%m-%d")
        }
      end
    end
  end
end
