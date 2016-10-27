module Kigo

  # +Kigo::ResponseParser+
  #
  # This class is responsible for decoding the response sent by Kigo's API
  # for different API calls.
  #
  # Usage
  #
  #   parser = Kigo::ResponseParser.new
  #   parser.compute_pricing(params, response_body)
  #   # => #<Result error=nil value=Quotation>
  #
  # See documentation of this class instance methods for their description
  # and possible errors.
  class ResponseParser
    include Concierge::JSON

    DATES_NOT_AVAILABLE_MSG = "Dates not available"
    CHECK_IN_TOO_FAR_MSG = "Unfortunately we do not allow bookings over 366 days into the future"

    attr_reader :params

    def initialize(params)
      @params = params
    end

    # parses the response of a +computePricing+ API call.
    #
    # Returns a +Result+ instance wrapping a +Quotation+ object
    # in case the response is successful. Possible errors that could
    # happen in this step are:
    #
    # +invalid_json_representation+: the response sent back is not a valid JSON.
    # +quote_call_failed+:           the response status is not +E_OK+.
    # +unrecognised_response+:       the response was successful, but the format cannot
    #                                be parsed.
    def compute_pricing(response)
      decoded_payload = json_decode(response)
      return decoded_payload unless decoded_payload.success?

      payload = decoded_payload.value

      if payload["API_RESULT_CODE"] == "E_OK"
        reply = payload["API_REPLY"]
        return missing_field_error("API_REPLY") unless reply

        currency = reply["CURRENCY"]
        return missing_field_error("CURRENCY") unless currency

        total = reply["TOTAL_AMOUNT"]
        return missing_field_error("TOTAL_AMOUNT") unless total

        quotation = build_available_quotation(params, currency, total)
        Result.new(quotation)
      elsif error_should_be_silenced?(payload)
        Result.new(build_unavailable_quotation(params))
      elsif check_in_too_far?(payload)
        check_in_too_far_error
      else
        non_successful_result_error
      end
    end

    # parses the response of a +createConfirmedReservation+ API call.
    #
    # Returns a +Result+ instance wrapping a +Reservation+ object
    # in case the response is successful. Possible errors that could
    # happen in this step are:
    #
    # +invalid_json_representation+: the response sent back is not a valid JSON.
    # +booking_call_failed+:         the response status is not +E_OK+.
    # +unrecognised_response+:       the response was successful, but the format cannot
    #                                be parsed.
    def parse_reservation(response)
      decoded_payload = json_decode(response)
      return decoded_payload unless decoded_payload.success?

      payload     = Concierge::SafeAccessHash.new(decoded_payload.value)
      reservation = build_reservation(params)

      if payload["API_RESULT_CODE"] == "E_OK"
        code = payload.get("API_REPLY.RES_ID")
        return missing_field_error("RES_ID") unless code

        reservation.reference_number = code
        Result.new(reservation)
      elsif payload["API_RESULT_CODE"] == "E_CONFLICT" && payload["API_RESULT_TEXT"] == DATES_NOT_AVAILABLE_MSG
        dates_not_available_error
      else
        non_successful_result_error
      end
    end

    # parses the response of a +cancelReservation+ API call.
    # Returns a +Result+ instance wrapping a +reference_number+ param
    # in case the response is successful.
    def parse_cancellation(response)
      payload = json_decode(response)
      return payload unless payload.success?

      case payload.value["API_RESULT_CODE"]
      when 'E_OK'
        Result.new(params[:reference_number])
      when 'E_NOSUCH'
        reservation_not_found_error
      when 'E_ALREADY'
        already_cancelled_error
      else
        cancellation_failed_error
      end
    end

    private

    # Not all errors from Kigo API are errors in terms of our business logic,
    # so this method determines whether we should consider error from Kigo API
    # as normal response or not.
    def error_should_be_silenced?(payload)
      property_not_available_for_selected_period?(payload) ||
      property_pricing_not_available_for_selected_period?(payload) ||
      property_pricing_not_available_or_calculation_is_disabled?(payload)
    end

    # Kigo uses the same result code (+E_NOSUCH+) to indicate when a property ID
    # is unknown and when the property exists, but is unavailable for the selected
    # dates. To determine which is the case, it is necessary to parse the
    # +API_RESULT_TEXT+ and check if it mentions that the property is unavailable
    # for the requested dates.
    def property_not_available_for_selected_period?(payload)
      payload["API_RESULT_CODE"] == "E_NOSUCH" && payload["API_RESULT_TEXT"] =~ /is not available for your selected period/
    end

    # The only possible message for an +E_LIMIT+ error, according to Kigo's
    # documentation, is for the following message:
    #
    #   The property pricing information is unavailable for the specified check-in/check-out dates
    #
    # When there are no rates available for the selected dates, this message is returned
    # by Kigo and KigoLegacy's API. This is not an error situation, and the property
    # should be deemed unavailable.
    def property_pricing_not_available_for_selected_period?(payload)
      payload["API_RESULT_CODE"] == "E_LIMIT"
    end

    # Most often, the error message associated with the +E_EMPTY+ errror is
    #
    #   The property pricing information is unavailable or the property pricing calculation is disabled.
    #
    # This means that either there are no availabilities for the property,
    # or the selected dates are already booked. In either case, the property
    # should be considered unavailable.
    def property_pricing_not_available_or_calculation_is_disabled?(payload)
      payload["API_RESULT_CODE"] == "E_EMPTY"
    end

    # Error message is fired when user tries to quote prices with check_in
    # date in too far future.
    #
    # In that case Kigo's API original error message is:
    #
    # The property pricing information is unavailable due to a constraint.
    # Unfortunately we do not allow bookings over 366 days into the future.
    def check_in_too_far?(payload)
      payload["API_RESULT_CODE"] == "E_CONFLICT" && payload["API_RESULT_TEXT"] =~ /#{CHECK_IN_TOO_FAR_MSG}/
    end

    def build_reservation(params)
      Reservation.new(params)
    end

    def build_available_quotation(params, currency, total)
      quotation = Quotation.new(params)
      quotation.available = true
      quotation.currency  = currency
      quotation.total     = total.to_f
      quotation
    end

    def build_unavailable_quotation(params)
      quotation = Quotation.new(params)
      quotation.available = false
      quotation
    end

    def non_successful_result_error
      message = "The `API_RESULT_CODE` obtained was not equal to `E_OK`. Check Kigo's " +
        "API documentation for an explanation for the `API_RESULT_CODE` returned."

      mismatch(message, caller)
      Result.error(:unrecognised_response, message)
    end

    def check_in_too_far_error
      Result.error(:check_in_too_far, "Selected check-in date is too far")
    end

    def dates_not_available_error
      message = DATES_NOT_AVAILABLE_MSG

      mismatch(message, caller)
      Result.error(:unavailable_dates, message)
    end

    def reservation_not_found_error
      message = 'The reservation was not found, or does not belong to your Rental Agency Kigo account.'
      mismatch(message, caller)
      Result.error(:reservation_not_found, message)
    end

    def already_cancelled_error
      message = 'The reservation already cancelled'
      mismatch(message, caller)
      Result.error(:already_cancelled, message)
    end

    def cancellation_failed_error
      message = 'Undefined error result'
      mismatch(message, caller)
      Result.error(:cancellation_failed, message)
    end

    def missing_field_error(name)
      message = "Response does not contain mandatory field `#{name}`."
      mismatch(message, caller)
      Result.error(:unrecognised_response, message)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(response_mismatch)
    end
  end

end
