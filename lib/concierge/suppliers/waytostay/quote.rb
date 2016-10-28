module Waytostay
  #
  # Handles all things quote related for waytostay
  #
  module Quote
    include Concierge::Errors::Quote

    ENDPOINT = "/bookings/quote".freeze
    SILENCED_ERROR_MESSAGES = [
      "Apartment is not available for the selected dates",
    ].freeze
    STAY_TOO_SHORT_ERROR_MESSAGE    = /The minimum number of nights to book this apartment is (\d+)/
    CHECK_IN_TOO_NEAR_ERROR_MESSAGE = "Cut off days restriction"
    CHECK_IN_TOO_FAR_ERROR_MESSAGE  = "Max days for arrival restriction"
    REQUIRED_RESPONSE_KEYS = [
      "booking_details.property_reference",
      "booking_details.arrival_date",
      "booking_details.departure_date",
      "booking_details.number_of_adults",
      "pricing.pricing_summary.gross_total",
      "pricing.currency"
    ].freeze

    # Quote prices
    #
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a +Result.error+ when operation fails
    def quote(params)
      json = build_payload(params)
      result = oauth2_client.post(ENDPOINT, body: json, headers: headers)

      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        return missing_keys_error(missing_keys) unless missing_keys.empty?

        Result.new(build_quotation(response))
      elsif error_should_be_silenced?(result)
        Result.new(build_unavailable_quotation(params))
      elsif stay_too_short?(result)
        stay_too_short(min_stay_from_error(result))
      elsif check_in_too_near?(result)
        check_in_too_near
      elsif check_in_too_far?(result)
        check_in_too_far
      else
        result
      end
    end

    private
    def build_payload(params)
      {
        property_reference: params[:property_id],
        arrival_date:       params[:check_in],
        departure_date:     params[:check_out],
        number_of_adults:   params[:guests],
        payment_option:     Waytostay::Client::SUPPORTED_PAYMENT_METHOD
      }.to_json
    end

    def build_quotation(response)
      Quotation.new(quote_params_from(response))
    end

    def build_unavailable_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in],
        check_out:   params[:check_out],
        guests:      params[:guests],
        available:   false
      )
    end

    def error_should_be_silenced?(result)
      SILENCED_ERROR_MESSAGES.any? do |msg|
        result.error.data.to_s.include?(msg)
      end
    end

    def stay_too_short?(result)
      !!min_stay_from_error(result)
    end

    def min_stay_from_error(result)
      match_data = result.error.data.to_s.match(STAY_TOO_SHORT_ERROR_MESSAGE)
      match_data ? match_data[1] : nil
    end

    def check_in_too_near?(result)
      result.error.data.to_s.include?(CHECK_IN_TOO_NEAR_ERROR_MESSAGE)
    end

    def check_in_too_far?(result)
      result.error.data.to_s.include?(CHECK_IN_TOO_FAR_ERROR_MESSAGE)
    end

    # Returns the hash that can be plugged into Quotation initialization.
    # +response+ is a Concierge::SafeAccessHash
    #
    def quote_params_from(response)
      {
        property_id:         response.get("booking_details.property_reference"),
        check_in:            response.get("booking_details.arrival_date"),
        check_out:           response.get("booking_details.departure_date"),
        guests:              response.get("booking_details.number_of_adults"),
        total:               response.get("pricing.pricing_summary.gross_total"),
        currency:            response.get("pricing.currency"),
        available:           true
      }
    end
  end
end
