module Poplidays

  # +Poplidays::Price+
  #
  # This class is responsible for performing price quotations for properties coming
  # from Poplidays, parsing the response and building the +Quotation+ object according
  # with the data returned by their API.
  #
  # Usage
  #
  #   result = Poplidays::Price.new.quote(stay_params)
  #   if result.success?
  #     process_quotation(result.value)
  #   else
  #     handle_error(result.error)
  #   end
  #
  # The price quotation API call is open - it requires no authentication. Therefore
  # no parameters are required to build this class.
  #
  # The +quote+ method returns a +Result+ object that, when successful, encapsulates
  # the resulting +Quotation+ object. Possible errors at this stage are:
  #
  # * +unrecognised_response+:           happens when the request was successful, but the format
  #                                      of the response is not compatible to this class' expectations.
  # * +unsupported_on_request_property+: only properties that require no confirmation are
  #                                      supported at this moment. If the property has no
  #                                      automatic confirmation, this is an error.
  class Price
    include Concierge::JSON

    # base URI for API calls. All calls are relative to this endpoint.
    BASE_URI = "https://api.poplidays.com"

    # Poplidays support XML and JSON responses, the former being the default.
    # Therefore, every API call need to explicitly indicate that a JSON
    # response is preferred.
    HEADERS  = { "Accept" => "application/json" }

    # currency information is not included in the response, but prices are
    # always quoted in EUR.
    CURRENCY = "EUR"

    # some API calls are cached using +Concierge::Cache+ and this is the cache
    # key prefix used for those entries.
    CACHE_PREFIX = "poplidays.quote"

    # Checks the price with Poplidays. Downloads the availabilities calendar
    # and checks whether the selected dates are available. If so, the price
    # is extracted.
    #
    # Properties have also "mandatory services". These need to be accounted
    # for when calculating the subtotal. For that purpose, an API call to
    # the property details endpoint is made and that value is extracted.
    def quote(params)
      cache_key = ["availabilities", ".", params[:property_id]].join
      calendar = fetch_with_cache(cache_key, availabilities_calendar_endpoint(params[:property_id]))
      return calendar unless calendar.success?

      availability_calculation = check_availability(calendar.value, params[:check_in], params[:check_out])
      return availability_calculation unless availability_calculation.success?

      quotation = build_quotation(params)
      availability = availability_calculation.value

      if availability
        # no support for on-request properties. Only properties with instant confirmation
        # should exist on Roomorama.
        if availability["requestOnly"] == true
          no_instant_confirmation
          return Result.error(:unsupported_on_request_property, "Request Only")
        end

        mandatory_services = retrieve_mandatory_services(params[:property_id])
        return mandatory_services unless mandatory_services.success?

        quotation.available = true
        quotation.total     = (availability["price"].to_f + mandatory_services.value.to_f).ceil
      else
        quotation.available = false
      end

      Result.new(quotation)
    end

    private

    # checks if there is an entry in the availabilities calendar that matches
    # the +check_in+ and +check_out+ dates given. Dates in the response
    # are in the format +YYYYMMDD+ (no dashes), so we need to transform our
    # dates to that format when comparing.
    def check_availability(calendar, check_in, check_out)
      availabilities = calendar["availabilities"]
      unless availabilities.is_a? Array
        no_availabilities_collection
        return unrecognised_response(calendar)
      end

      formatted_check_in  = check_in.to_s.gsub("-", "")
      formatted_check_out = check_out.to_s.gsub("-", "")

      availability = availabilities.find do |availability|
        availability["arrival"] == formatted_check_in && availability["departure"] == formatted_check_out
      end

      Result.new(availability)
    end

    def retrieve_mandatory_services(id)
      cache_key      = ["mandatory_services", ".", id].join
      cache_duration = 12 * 60 * 60 # twelve hours

      with_cache(cache_key, freshness: cache_duration) do
        property_details = fetch_json(property_endpoint(id))
        return property_details unless property_details.success?

        data = json_decode(property_details.value)
        return data unless data.success?

        payload = data.value

        if payload.key?("mandatoryServicesPrice")
          Result.new(payload["mandatoryServicesPrice"])
        else
          no_mandatory_services_data
          unrecognised_response(payload)
        end
      end
    end

    def fetch_json(endpoint)
      result = http.get(endpoint, {}, HEADERS)

      if result.success?
        response = result.value
        Result.new(response.body)
      else
        result
      end
    end

    # uses +fetch_json+ to fetch the JSON payload from the given +endpoint+,
    # leveraging the cache with key +key+.
    def fetch_with_cache(key, endpoint)
      payload = with_cache(key) do
        fetch_json(endpoint)
      end

      if payload.success?
        json_decode(payload.value)
      else
        payload
      end
    end

    def with_cache(key, freshness: Concierge::Cache::DEFAULT_TTL)
      cache.fetch(key, freshness: freshness) { yield }
    end

    def cache
      @_cache ||= Concierge::Cache.new(namespace: CACHE_PREFIX)
    end

    def build_quotation(params)
      Quotation.new(
        property_id: params[:property_id],
        check_in:    params[:check_in].to_s,
        check_out:   params[:check_out].to_s,
        guests:      params[:guests],
        currency:    CURRENCY
      )
    end

    def property_endpoint(id)
      [BASE_URI, "/v2/lodgings/", id].join
    end

    def availabilities_calendar_endpoint(id)
      [BASE_URI, "/v2/lodgings/", id, "/availabilities"].join
    end

    def http
      @http ||= Concierge::HTTPClient.new(BASE_URI)
    end

    def unrecognised_response(response)
      Result.error(:unrecognised_response, response.to_s)
    end

    def no_instant_confirmation
      message = "On request properties are not supported in the Poplidays integration. " +
        "The `requestOnly` field was set to `true`, meaning the booking requires host confirmation."

      mismatch(message, caller)
    end

    def no_availabilities_collection
      message = "Expected a collection of availability information under the " +
        "`availabilities` field, none was found."

      mismatch(message, caller)
    end

    def no_mandatory_services_data
      message = "Expected to find the price for mandatory services under the " +
        "`mandatoryServicesPrice`, but none was found."

      mismatch(message, caller)
    end

    def mismatch(message, backtrace)
      response_mismatch = Concierge::Context::ResponseMismatch.new(
        message:   message,
        backtrace: backtrace
      )

      API.context.augment(response_mismatch)
    end
  end

end
