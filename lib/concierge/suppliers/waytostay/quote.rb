module Waytostay
  #
  # Handles all things quote related for waytostay
  #
  module Quote

    ENDPOINT = "/bookings/quote"
    UNAVAILBLE_ERROR_MESSAGE = "Apartment is not available for the selected dates"
    REQUIRED_RESPONSE_KEYS = [
      "booking_details.property_reference",
      "booking_details.arrival_date",
      "booking_details.departure_date",
      "booking_details.number_of_adults",
      "booking_details.price.pricing_summary.final_price",
      "booking_details.price.currency"
    ]

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      post_body = {
        property_reference: params[:property_id],
        arrival_date:       params[:check_in],
        departure_date:     params[:check_out],
        number_of_adults:   params[:guests]
      }
      result = oauth2_client.post(ENDPOINT,
                                  body: post_body.to_json,
                                  headers: headers)

      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)

        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          Quotation.new(quote_params_from(response))
        else
          augment_missing_fields(missing_keys)
          announce_error("quote", Result.error(:unrecognised_response))
          Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
        end

      elsif unavailable?(result) # for waytostay, unavailable is returned as a 422 error

        Quotation.new({
          property_id: params[:property_id],
          check_in:    params[:check_in],
          check_out:   params[:check_out],
          guests:      params[:guests],
          available:   false
        })

      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    private

    def unavailable?(result)
      result.error.data && result.error.data.include?(UNAVAILBLE_ERROR_MESSAGE)
    end

    # Returns the hash that can be plugged into Quotation initialization.
    # +response+ is a Concierge::SafeAccessHash
    #
    def quote_params_from(response)
      {
        property_id: response.get("booking_details.property_reference"),
        check_in:    response.get("booking_details.arrival_date"),
        check_out:   response.get("booking_details.departure_date"),
        guests:      response.get("booking_details.number_of_adults"),
        total:       response.get("booking_details.price.pricing_summary.final_price"),
        currency:    response.get("booking_details.price.currency"),
        available:   true,
      }
    end

  end
end
