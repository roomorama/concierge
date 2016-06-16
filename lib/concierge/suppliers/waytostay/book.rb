module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Book

    ENDPOINT = "/bookings"
    DEFAULT_CUSTOMER_LANGUAGE = "EN"
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ]

    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      post_body = {
        email_address:      params[:customer][:email],
        name:               params[:customer][:first_name],
        surname:            params[:customer][:last_name],
        cell_phone:         params[:customer][:phone],
        language:           DEFAULT_CUSTOMER_LANGUAGE,
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

        if contains_all?(REQUIRED_RESPONSE_KEYS, response)
          reservation = Reservation.new(params)
          reservation.code = response.get("booking_reference")
          reservation
        else
          announce_error("booking", Result.error(:unrecognised_response))
          Reservation.new(errors: { booking: "Could not create booking with remote supplier" })
        end

      else
        announce_error("booking", result)
        Reservation.new(errors: { booking: "Could not create booking with remote supplier" })
      end
    end

  end
end

