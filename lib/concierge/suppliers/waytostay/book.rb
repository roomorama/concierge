module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Book

    ENDPOINT_BOOKING = "/bookings".freeze
    ENDPOINT_CONFIRMATION = "/bookings/:booking_reference/confirmation".freeze
    DEFAULT_CUSTOMER_LANGUAGE = "EN".freeze
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ].freeze

    # Books and immediately confirms the waytostay booking
    #
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def book(params)
      remote_book(params).tap do |result|
        remote_confirm(result.value, params) if result.success?
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
        agent_reference:    params[:inquiry_id],
        payment_option:     Waytostay::Client::SUPPORTED_PAYMENT_METHOD
      }
      result = oauth2_client.post(ENDPOINT_BOOKING,
                                  body: post_body.to_json,
                                  headers: headers)
      parse_reservation(result, params)
    end

    # Always returns a +Reservation+.
    def remote_confirm(reservation, params)
      result = oauth2_client.post(
        build_path(ENDPOINT_CONFIRMATION, booking_reference: reservation.reference_number),
        headers: headers
      )
      parse_reservation(result, params)
    end

    private

    # Takes a +Result+ and returns a +Reservation+
    #
    def parse_reservation(result, params)
      return result unless result.success?

      response = Concierge::SafeAccessHash.new(result.value)

      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        reservation = Reservation.new(params)
        reservation.reference_number = response.get("booking_reference")
        Result.new(reservation)
      else
        augment_missing_fields(missing_keys)
        Result.error(:unrecognised_response)
      end
    end

  end
end

