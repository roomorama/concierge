module Waytostay
  #
  # Handles the fetching of availability
  #
  module Availability
    ENDPOINT = "/properties/:property_reference/availability".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.properties_availability", "_links" ].freeze

    def update_availabilities(roomorama_property)
      first_page_path = build_path(ENDPOINT, property_reference: roomorama_property.identifier)
      update_availabilities_per_page(roomorama_property, first_page_path)
    end

    private

    def update_availabilities_per_page(roomorama_property, page_path)
      if page_path.nil?
        return Result.new(roomorama_property) # return the result, this is the last page
      end

      result = oauth2_client.get(page_path, headers: headers)

      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)

        if missing_keys.empty?
          parse_availability!(response, roomorama_property)
          update_availabilities_per_page(roomorama_property, next_page_path(response))
        else
          augment_missing_fields(missing_keys)
          Result.error(:unrecognised_response)
        end
      else
        result
      end

    end

    def parse_availability!(response, roomorama_property)
      response.get("_embedded.properties_availability").each do |entry|
        available = entry["status"] != "unavailable"
        Date.parse(entry["start_date"]).upto Date.parse(entry["end_date"]) do |date|
          roomorama_property.update_calendar(date.to_s => available)
        end
      end
    end

    # return the link for the next page, or nil if it is the last page
    def next_page_path response
      response.get("_links.next.href")
    end
  end
end
