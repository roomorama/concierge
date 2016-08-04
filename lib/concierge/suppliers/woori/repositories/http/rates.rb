module Woori::Repositories::HTTP
  # +Woori::Repositories::HTTP::UnitRates+
  #
  # This class is responsible for wrapping the logic related to fetching 
  # unit rates from Woori, parsing the response, and building the
  # +Result+ object
  class UnitRates < Base
    ENDPOINT = "available"

    # Retrieves rates for unit by unit_id
    #
    # Arguments
    #
    #   * +unit_id+ [String] unit id (room code hash)
    #
    # Usage
    #
    #   repository = Woori::Repositories::HTTP::UnitRates.new(credentials)
    #   result = repository.find_rates("w_w0104006")
    #
    # Returns a +Result+ wrapping +Entities::UnitRates+ object
    # when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def find_rates(unit_id)
      params = build_request_params(unit_id)
      result = http.get(ENDPOINT, params, headers)

      if result.success?
        decoded_result = json_decode(result.value.body)
        
        if decoded_result.success?
          safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
          mapper = Woori::Mappers::UnitRates.new(safe_hash)
          unit_rates = mapper.build_unit_rates
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
