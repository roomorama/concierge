module Waytostay
  #
  # Handles the fetching of availability
  #
  module Availability
    ENDPOINT = "/properties/:property_reference/availability".freeze
    RATES_ENDPOINT = "/properties/:property_reference/rates".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.properties_availability", "_links" ].freeze

    # Return a Result wrapping a list of Roomorama::Calendar::Entries.
    # This method will trigger calls to both /availability and /rates
    # without any start_date/end_date, to get informatino for one year from today
    #
    def get_availabilities(identifier)
      calendar_entries = []
      current_page = build_path(ENDPOINT, property_reference: identifier) # first page have no page number
      while current_page && !current_page.empty? do
        result = oauth2_client.get(current_page, headers: headers)
        return result unless result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        availability_entries_reuslt = availabilities_per_page(response)
        return availability_entries_reuslt unless availability_entries_reuslt.success?
        calendar_entries << availability_entries_reuslt.value
        current_page = next_page_url(response)
      end

      calendar_entries.flatten! # they were in nested arrays by pages

      end_date = calendar_entries.last.date

      rates_result = oauth2_client.get(build_path(RATES_ENDPOINT, property_reference: identifier),
                                       params: {end_date: end_date.to_s}, # with no start date, to get rates from today
                                       headers: headers)
      return rates_result unless rates_result.success?
      response = Concierge::SafeAccessHash.new(rates_result.value)
      property_rates = response.get("_embedded.properties_rates")
      append_rates!(calendar_entries, property_rates)

      Result.new(calendar_entries)
    end

    private

    def availabilities_per_page(response)
      missing_keys = response.missing_keys_from(REQUIRED_RESPONSE_KEYS)
      if missing_keys.empty?
        Result.new(parse_calendar_entries(response))
      else
        augment_missing_fields(missing_keys)
        Result.error(:unrecognised_response)
      end
    end

    def parse_calendar_entries(response)
      entries = []
      response.get("_embedded.properties_availability").each do |entry|
        available = entry["status"] != "unavailable"
        Date.parse(entry["start_date"]).upto Date.parse(entry["end_date"]) do |date|
          entries << Roomorama::Calendar::Entry.new(
            date:      date.to_s,
            available: available
          )
        end
      end
      entries
    end

    # Adds the nightly rate into calendar entries. The property_rates given has the format:
    # [ {"start_date": "2016-07-21",
    #    "end_date": "2016-07-21",
    #    "per_person": {
    #      "1": 217.2,
    #      "2": 217.2,
    #      "3": 217.2,
    #      "4": 217.2}
    # } ]
    #
    def append_rates!(calendar_entries, property_rates)
      property_rates.each do |rate|
        Date.parse(rate["start_date"]).upto(Date.parse(rate["end_date"])) do |date|
          date_string = date.to_s
          entry_found = false
          calendar_entries.map do |entry|
            if entry.date.to_s == date_string
              entry.nightly_rate = rate["per_person"]["1"]
              entry_found = true
            end
          end
          unless entry_found
            calendar_entries << Roomorama::Calendar::Entry.new(
              date:         date_string,
              available:    true,
              nightly_rate: rate["per_person"]["1"]
            )
          end
        end
      end
    end

    # return the link for the next page, or nil if it is the last page
    def next_page_url(response)
      response.get("_links.next.href")
    end
  end
end
