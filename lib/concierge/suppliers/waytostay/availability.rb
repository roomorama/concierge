module Waytostay
  #
  # Handles the fetching of availability
  #
  module Availability
    ENDPOINT = "/properties/:property_reference/availability".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.properties_availability", "_links" ].freeze

    def update_availabilities(roomorama_property)
      first_page_path = build_path(ENDPIONT, property_reference: roomorama_property.identifier)
      update_availabilities_per_page(roomorama_property, first_page_path)
    end

    private

    def update_availabilities_per_page(roomorama_property, page_path)
      result = oauth2_client.get(page_path, headers: headers)
      if result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
        if missing_keys.empty?
          response.get("_embedded_properties_availability").each do |entry|
            available = entry["status"] != "unavailable"
            Date.parse(entry["start_date"]).upto to Date.parse(entry["end_date"]) do |date|
              roomorama_property.update_calendar(date.to_s => available)
            end
          end
          next_page_path = response.get("_links.next.href") # next page this is nil, this is the last iteration
          if next_page_path
            update_availabilities_per_page(roomorama_property, next_page_path)
          else
            Result.new(roomorama_property) # return the result, this is the last page
          end
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
