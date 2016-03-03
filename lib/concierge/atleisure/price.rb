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
  class Price
    ENDPOINT = "https://checkavailabilityv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm"

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
        return Result.error(:unsupported_on_request_property, params.to_s)
      end

      if response["Available"] == "Yes"
        price = response["CorrectPrice"] || response["Price"]
        if price
          quotation.available = true
          quotation.total     = price
          return Result.new(quotation)
        else
          unrecognised_response(response)
        end

      elsif response["Available"] == "No"
        quotation.available = false
        return Result.new(quotation)

      else
        unrecognised_response(response)
      end
    end

    def build_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in].to_s,
        check_out:   params[:check_out].to_s,
        guests:      params[:guests]
      )
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response, response.to_s)
    end

    def jsonrpc(endpoint)
      API::Support::JSONRPC.new(endpoint)
    end

    def endpoint(name)
      ENDPOINTS.fetch(name)
    end

    def authentication_params
      @authentication_params ||= {
        "WebpartnerCode"     => credentials.username,
        "WebpartnerPassword" => credentials.password
      }
    end

  end

end
