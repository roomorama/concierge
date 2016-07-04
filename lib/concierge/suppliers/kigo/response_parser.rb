module Kigo

  # +Kigo::ResponseParser+
  #
  # This class is responsible for decoding the response sent by Kigo's API
  # for different API calls.
  #
  # Usage
  #
  #   parser = Kigo::ResponseParser.new
  #   parser.compute_pricing(request_params, response_body)
  #   # => #<Result error=nil value=Quotation>
  #
  # See documentation of this class instance methods for their description
  # and possible errors.
  class ResponseParser
    include Concierge::JSON

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
    def compute_pricing(request_params, response)
      decoded_payload = json_decode(response)
      return decoded_payload unless decoded_payload.success?

      payload = decoded_payload.value
      quotation = build_quotation(request_params)

      if payload["API_RESULT_CODE"] == "E_OK"
        reply = payload["API_REPLY"]
        unless reply
          no_field("API_REPLY")
          return unrecognised_response
        end

        currency = reply["CURRENCY"]
        fees     = reply["FEES_AMOUNT"]
        total    = reply["TOTAL_AMOUNT"]

        { "CURRENCY" => currency, "FEES_AMOUNT" => fees, "TOTAL_AMOUNT" => total }.each do |key, value|
          if !value
            no_field(value)
            return unrecognised_response
          end
        end

        quotation.available = true
        quotation.currency  = currency
        quotation.total     = total.to_i + fees.to_i

        Result.new(quotation)
      elsif payload["API_RESULT_CODE"] == "E_NOSUCH" && payload["API_RESULT_TEXT"] =~ /is not available for your selected period/
        # Kigo uses the same result code (+E_NOSUCH+) to indicate when a property ID
        # is unknown and when the property exists, but is unavailable for the selected
        # dates. To determine which is the case, it is necessary to parse the
        # +API_RESULT_TEXT+ and check if it mentions that the property is unavailable
        # for the requested dates.

        quotation.available = false
        Result.new(quotation)
      else
        non_successful_result_code
        Result.error(:quote_call_failed)
      end
    end

    private

    def build_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in],
        check_out:   params[:check_out],
        guests:      params[:guests],
      )
    end

    def unrecognised_response
      Result.error(:unrecognised_response)
    end

    def non_successful_result_code
      message = "The `API_RESULT_CODE` obtained was not equal to `E_OK`. Check Kigo's " +
        "API documentation for an explanation for the `API_RESULT_CODE` returned."

      mismatch(message, caller)
    end

    def no_field(name)
      message = "Response does not contain mandatory field `#{name}`."
      mismatch(message, caller)
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
