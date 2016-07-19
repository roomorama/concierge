module Waytostay
  #
  # Calls and parse the /changes endpoint from waytostay
  #
  module Changes

    ENDPOINT = "/changes".freeze
    REQUIRED_RESPONSE_KEYS = [ "properties.reference", "properties_media.reference",
      "properties_availability.reference", "properties_rates.reference",
      "properties_reviews.reference", "bookings.reference" ].freeze

    # Returns a +Result+ wrapped hash of properties ref that changed, looking like:
    #   { properties: ["a", "b", "c"], media: ["c", "d"] }
    #
    # If last_synced_timestamp is nil, returns a "full set of all currently active properties"
    # See https://apis.waytostay.com/doc/swagger/WaytostayApi-v4#!/Changes/get_changes
    #
    # Augments missing fields in the response if there are any
    #
    def get_changes_since(last_synced_timestamp)
      params = {timestamp: last_synced_timestamp} if last_synced_timestamp
      result = oauth2_client.get(ENDPOINT,
                                 params: params,
                                 headers: headers)

      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)

        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          Result.new( {
            properties: response.get("properties.reference"),
            media: response.get("properties_media.reference"),
            availability: response.get("properties_availability.reference"),
            # rates: response.get("properties_rates.reference"), #TODO: remove this commented field when full calendar sync is implemented
            # reviews: response.get("properties_reviews.reference"), #TODO: remove this comented field when booking sync is implemented
            # bookings: response.get("bookings.reference"), #TODO: remove this comented field when booking sync is implemented
          })
        else
          augment_missing_fields(missing_keys)
          Result.error(:unrecognised_response)
        end
      else
        result
      end
    end

  end
end

