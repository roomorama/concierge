module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Cancel

    ENDPOINT = "bookings/:reservation_id/cancel"
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ]

    # Books and immediately confirms the waytostay booking
    #
    # Always returns a +Result+.
    def cancel(params)
      oauth2_client.post(ENDPOINT.gsub(:reservation_id, params.reservation_id))
    end
  end
end

