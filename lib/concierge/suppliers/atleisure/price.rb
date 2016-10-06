module AtLeisure

  # +AtLeisure::Price+
  #
  # This class is responsible for wrapping the logic related to making a price quotation
  # to AtLeisure, parsing the response, and building the +Quotation+ object with the data
  # returned from their API.
  #
  # Usage
  #
  #   result = AtLeisure::Price.new(credentials).quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates the
  # resulting +Quotation+ object.
  #
  # Possible errors at this stage are:
  #
  # * +unrecognised_response+:           happens when the request was successful, but the format
  #                                      of the response is not compatible to this class' expectations.
  # * +unsupported_on_request_property+: only properties that require no confirmation are
  #                                      supported at this moment. If the property has no
  #                                      automatic confirmation, this is an error.
  # * +host_not_found+:                  happens when host is not found for AtLeisure supplier
  class Price
    ENDPOINT = "https://checkavailabilityv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"
    CURRENCY = "EUR"
    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Calls the CheckAvailabilityV1 method from the AtLeisure JSON-RPC interface.
    # Returns a +Result+ object.
    def quote(params)
      stay_details = {
        "HouseCode"     => params[:property_id],
        "ArrivalDate"   => params[:check_in].to_s,
        "DepartureDate" => params[:check_out].to_s,
        "Price"         => 0
      }.merge!(authentication_params)

      client = jsonrpc(ENDPOINT)
      result = client.invoke("CheckAvailabilityV1", stay_details)

      if result.success?
        parse_quote_response(params, result.value)
      else
        result
      end
    end

    private

    def parse_quote_response(params, response)
      quotation = build_quotation(params)

      if response["OnRequest"] == "Yes"
        no_instant_confirmation
        return Result.error(:unsupported_on_request_reservation)
      end

      if response["Available"] == "Yes"
        price = response["CorrectPrice"] || response["Price"]
        if price
          quotation.available = true
          quotation.total     = price
          return Result.new(quotation)
        else
          no_price_information
          unrecognised_response(response)
        end

      elsif response["Available"] == "No"
        quotation.available = false
        return Result.new(quotation)

      else
        no_availability_information
        unrecognised_response(response)
      end
    end

    def build_quotation(params)
      Quotation.new(
        property_id:         params[:property_id],
        check_in:            params[:check_in].to_s,
        check_out:           params[:check_out].to_s,
        guests:              params[:guests],
        currency:            CURRENCY,
      )
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response)
    end

    def jsonrpc(endpoint)
      Concierge::JSONRPC.new(endpoint)
    end

    def no_instant_confirmation
      message = "Roomorama can only work with properties with instant confirmation from AtLeisure." +
        " However, the `OnRequest` field for given period was set to `true`."

      mismatch(message, caller)
    end

    def no_price_information
      message = "No price information could be retrieved. Searched fields `CorrectPrice`" +
        " and `Price` and neither is given."

      mismatch(message, caller)
    end

    def no_availability_information
      message = "Could not determine if the property was available. The `Available` field" +
        " was not given or has an invalid value."

      mismatch(message, caller)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      Concierge.context.augment(response_mismatch)
    end

    def authentication_params
      @authentication_params ||= {
        "WebpartnerCode"     => credentials.username,
        "WebpartnerPassword" => credentials.password
      }
    end

  end

end
