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
  # See documentation of this class instace methods for their description
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
        return unrecognised_response(response) unless reply

        currency = reply["CURRENCY"]
        fees     = reply["FEES_AMOUNT"]
        total    = reply["TOTAL_AMOUNT"]

        if !currency || !fees || !total
          return unrecognised_response(response)
        end

        quotation.available = true
        quotation.currency  = currency
        quotation.fee       = fees.to_i
        quotation.total     = total.to_i

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
        Result.error(:quote_call_failed, payload.to_s)
      end
    end

    private

    def build_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in].to_s,
        check_out:   params[:check_out].to_s,
        guests:      params[:guests],
      )
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response, response.to_s)
    end
  end

end
