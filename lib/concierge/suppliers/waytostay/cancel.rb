module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Cancel

    ENDPOINT = "/bookings/:reservation_id/cancel"
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ]

    # Books and immediately confirms the waytostay booking
    #
    # Always returns a +Result+.
    def cancel(params)
      cancellation_result = oauth2_client.post(ENDPOINT.gsub(":reservation_id", params[:reservation_id]),
                         headers: headers)

      return cancellation_result unless cancellation_result.success?

      response = Concierge::SafeAccessHash.new(cancellation_result.value)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        Result.new(response.get("booking_reference"))
      else
        augment_missing_fields(missing_keys)
        Result.error(:response_mismatch)
      end

    end
  end
end

