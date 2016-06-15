module Waytostay
  #
  # Handles all things quote related for waytostay
  #
  module Quote

    ENDPOINT = "/bookings/quote"
    UNAVAILBLE_ERROR_MESSAGE = "Apartment is not available for the selected dates"

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      post_body = {
        property_reference: params.fetch(:property_id),
        arrival_date:       params.fetch(:check_in),
        departure_date:     params.fetch(:check_out),
        number_of_adults:   params.fetch(:guests)
      }
      result = oauth2_client.post(ENDPOINT,
                                  body: post_body.to_json,
                                  headers: headers)

      if result.success?
        Quotation.new(quote_params_from(result.value))
      elsif unavailable?(result)
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

    def quote_params_from(json)
      details = json["booking_details"]
      {
        property_id: details["property_reference"],
        check_in:    details["arrival_date"],
        check_out:   details["departure_date"],
        guests:      details["number_of_adults"],
        fee:         details["price"]["pricing_summary"]["agency"]["commission_amount"],
        total:       details["price"]["pricing_summary"]["final_price"],
        currency:    details["price"]["currency"],
        available:   true,
      }
    end
  end
end
