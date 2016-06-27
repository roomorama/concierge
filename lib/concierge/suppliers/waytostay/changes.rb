module Waytostay
  #
  # Handles all things booking related for waytostay
  #
  module Changes

    ENDPOINT = "/changes".freeze
    REQUIRED_RESPONSE_KEYS = [ "properties.reference", "properties_media.reference",
      "properties_availability.reference", "properties_rates.reference",
      "properties_reviews.reference", "bookings.reference" ].freeze

    # Returns a hash of properties ref that changed, looking like:
    #   { properties: ["a", "b", "c"], media: ["c", "d"] }
    #
    # If an error happens in any step in the process of getting a response back from
    # Waytostay, +nil+ is returned, and failure is logged.
    #
    def get_changes_since(last_synced_timestamp=nil)
      params = {timestamp: last_synced_timestamp} if last_synced_timestamp
      result = oauth2_client.get(ENDPOINT,
                                 params: params,
                                 headers: headers)

      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)

        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          {
            properties: response.get("properties.reference"),
            media: response.get("properties_media.reference"),
            availability: response.get("properties_availability.reference"),
            rates: response.get("properties_rates.reference"),
            reviews: response.get("properties_reviews.reference"),
            bookings: response.get("bookings.reference"),
          }
        else
          augment_missing_fields(missing_keys)
          announce_error("changes", Result.error(:unrecognised_response))
          nil
        end
      else
        announce_error("changes", result)
        nil
      end
    end

  end
end

