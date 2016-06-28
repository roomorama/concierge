module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Book

    ENDPOINT_BOOKING = "/bookings"
    ENDPOINT_CONFIRMATION = "/bookings/:booking_reference/confirmation"
    DEFAULT_CUSTOMER_LANGUAGE = "EN"
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ]

    # Books and immediately confirms the waytostay booking
    #
    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      remote_book(params).tap do |reservation|
        remote_confirm(reservation, params) if reservation.successful?
      end
    end

    # Always returns a +Reservation+.
    def remote_book(params)
      post_body = {
        email_address:      params[:customer][:email],
        name:               params[:customer][:first_name],
        surname:            params[:customer][:last_name],
        cell_phone:         params[:customer][:phone],
        language:           DEFAULT_CUSTOMER_LANGUAGE,
        property_reference: params[:property_id],
        arrival_date:       params[:check_in],
        departure_date:     params[:check_out],
        number_of_adults:   params[:guests],
        payment_option:     Waytostay::Client::SUPPORTED_PAYMENT_METHOD
      }
      result = oauth2_client.post(ENDPOINT_BOOKING,
                                  body: post_body.to_json,
                                  headers: headers)
      parse_reservation(result, params)
    end

    # Always returns a +Reservation+.
    def remote_confirm(reservation, params)
      result = oauth2_client.post(confirmation_path(reservation.code),
                                  headers: headers)
      parse_reservation(result, params)
    end

    private

    def confirmation_path ref
      return ENDPOINT_CONFIRMATION.gsub(/:booking_reference/, ref)
    end

    # Takes a +Result+ and returns a +Reservation+
    #
    def parse_reservation(result, params)
      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)

        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          reservation = Reservation.new(params)
          reservation.code = response.get("booking_reference")
          reservation
        else
          augment_missing_fields(missing_keys)
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

