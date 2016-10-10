module Waytostay
  #
  # Handles cancellation for waytostay
  #
  module Cancel

    ENDPOINT = "/bookings/:reference_number/cancellation"
    REQUIRED_RESPONSE_KEYS = [ "booking_reference" ]

    # Cancels a given reference_number
    #
    # Always returns a +Result+.
    # Augments any error on the request context.
    def cancel(params)
      cancellation_result = oauth2_client.post(ENDPOINT.gsub(":reference_number", params[:reference_number]),
                         headers: headers)

      return cancellation_result unless cancellation_result.success?

      response = Concierge::SafeAccessHash.new(cancellation_result.value)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        Result.new(response.get("booking_reference"))
      else
        augment_missing_fields(missing_keys)
        Result.error(:response_mismatch, "Missing keys: #{missing_keys}")
      end

    end
  end
end

