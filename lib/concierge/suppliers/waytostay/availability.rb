module Waytostay
  #
  # Handles the fetching of availability
  #
  module Availability
    ENDPOINT = "/properties/:property_reference/availability".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.properties_availability", "_links" ].freeze

    # Return a Result wrapping a list of Roomorama::Calendar::Entries.
    # Only availability field is filled in here. For rates, implementations
    # would be in the Waytostay::Rates module
    #
    def get_availabilities(identifier, nightly_rate)
      calendar_entries = []
      current_page = build_path(ENDPOINT, property_reference: identifier) # first page have no page number
      while current_page && !current_page.empty? do
        result = oauth2_client.get(current_page, headers: headers)
        return result unless result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        calendar_entries << availabilities_per_page(response, nightly_rate)
        current_page = next_page_url(response)
      end
      return Result.new(calendar_entries.flatten)
    end

    private

    def availabilities_per_page(response, nightly_rate)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        return parse_calendar_entries(response, nightly_rate)
      else
        augment_missing_fields(missing_keys)
        Result.error(:unrecognised_response)
      end
    end

    def parse_calendar_entries(response, nightly_rate)
      entries = []
      response.get("_embedded.properties_availability").each do |entry|
        available = entry["status"] != "unavailable"
        Date.parse(entry["start_date"]).upto Date.parse(entry["end_date"]) do |date|
          entries << Roomorama::Calendar::Entry.new(
            date:         date.to_s,
            available:    available,
            nightly_rate: nightly_rate
          )
        end
      end
      return entries
    end

    # return the link for the next page, or nil if it is the last page
    def next_page_url(response)
      response.get("_links.next.href")
    end
  end
end
