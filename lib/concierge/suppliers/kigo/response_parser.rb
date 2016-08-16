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
    # +property_not_found+:          the param's +property_id+ doesn't persist in our database.
    # +invalid_json_representation+: the response sent back is not a valid JSON.
    # +quote_call_failed+:           the response status is not +E_OK+.
    # +unrecognised_response+:       the response was successful, but the format cannot
    #                                be parsed.
    def compute_pricing(response)
      decoded_payload = json_decode(response)
      return decoded_payload unless decoded_payload.success?

      payload   = decoded_payload.value
      quotation = build_quotation(params)

      if payload["API_RESULT_CODE"] == "E_OK"
        reply = payload["API_REPLY"]
        unless reply
          no_field("API_REPLY")
          return unrecognised_response
        end

        currency = reply["CURRENCY"]
        total    = reply["TOTAL_AMOUNT"]

        { "CURRENCY" => currency, "TOTAL_AMOUNT" => total }.each do |key, value|
          if !value
            no_field(value)
            return unrecognised_response
          end
        end

        return property_not_found unless property
        return host_not_found unless host

        quotation.available           = true
        quotation.host_fee_percentage = host.fee_percentage
        quotation.currency            = currency
        quotation.total               = total.to_f

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
        unless code
          no_field("RES_ID")
          return unrecognised_response
        end

        reservation.reference_number = code
        Result.new(reservation)
      elsif payload["API_RESULT_CODE"] == "E_CONFLICT" && payload["API_RESULT_TEXT"] == "Dates not available"
        Result.error(:unavailable_dates)
      else
        non_successful_result_code
        Result.error(:booking_call_failed)
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
        message = 'The reservation was not found, or does not belong to your Rental Agency Kigo account.'
        mismatch(message, caller)
        Result.error(:reservation_not_found)
      when 'E_ALREADY'
        mismatch('The reservation already cancelled', caller)
        Result.error(:already_cancelled)
      end
    end

    private

    def build_reservation(params)
      Reservation.new(params)
    end

    def build_quotation(params)
      Quotation.new(params)
    end

    def unrecognised_response
      Result.error(:unrecognised_response)
    end

    def property_not_found
      Result.error(:property_not_found)
    end

    def host_not_found
      Result.error(:host_not_found)
    end

    def host
      @host ||= HostRepository.find(property.host_id)
    end

    def property
      @property ||= PropertyRepository.identified_by(params[:property_id]).first
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
