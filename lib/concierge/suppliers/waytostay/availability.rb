module Waytostay
  #
  # Handles the fetching of availability
  #
  module Availability
    CALENDAR_ENDPOINT = "/properties/:property_reference/calendar".freeze
    RATES_ENDPOINT = "/properties/:property_reference/rates".freeze
    REQUIRED_RESPONSE_KEYS = [ "_embedded.property_calendar", "_links" ].freeze

    # Return a Result wrapping a list of Roomorama::Calendar::Entries.
    # This method will trigger calls to both /availability and /rates
    # without any start_date/end_date, to get informatino for one year from today
    #
    def get_availabilities(identifier)
      calendar_entries = []
      # get calendar from today to one year from now
      current_page = build_path(CALENDAR_ENDPOINT, property_reference: identifier) # first page have no page number
      while current_page && !current_page.empty? do
        result = oauth2_client.get(current_page, headers: headers)
        return result unless result.success?
        response = Concierge::SafeAccessHash.new(result.value)
        calendar_page_entries = calendar_per_page(response)
        return calendar_page_entries unless calendar_page_entries.success?
        calendar_entries << calendar_page_entries.value
        current_page = next_page_url(response)
      end

      calendar_entries.flatten! # they were in nested arrays by pages

      # get rate from today to one year from now
      rates_result = oauth2_client.get(build_path(RATES_ENDPOINT, property_reference: identifier),
                                       headers: headers)
      return rates_result unless rates_result.success?
      response = Concierge::SafeAccessHash.new(rates_result.value)
      property_rates = response.get("_embedded.properties_rates")
      append_rates!(calendar_entries, property_rates)

      Result.new(calendar_entries)
    end

    private

    def calendar_per_page(response)
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
      Array(response.get("_embedded.property_calendar")).each do |entry_hash|
        entry = Concierge::SafeAccessHash.new entry_hash
        entries << Roomorama::Calendar::Entry.new(
          date:      entry.get("date"),
          available: entry.get("available"),
          checkin_allowed: !entry.get("closed_to_arrival"),
          checkout_allowed: !entry.get("closed_to_departure"),
          minimum_stay: entry.get("minimum_stay")
        )
      end
      entries
    end

    # Adds the nightly rate into calendar entries.
    # The property_rates given has the format:
    # [ {"start_date": "2016-07-21",
    #    "end_date": "2016-07-21",
    #    "per_person": {
    #      "1": 217.2,
    #      "2": 217.2,
    #      "3": 217.2,
    #      "4": 217.2}
    # } ]
    #
    # 2 notes:
    #
    #   - For dates where availability api did not cover, we assume it is avaiable.
    #
    #   - WayToStay provides us with data for a number of guests, and we chose to use
    #   the price for one guest since we don't support prices/per guest on a given
    #   date, and that is more accurate than using the host daily price.
    #
    #
    def append_rates!(calendar_entries, property_rates)
      property_rates.each do |rate|
        Date.parse(rate["start_date"]).upto(Date.parse(rate["end_date"])) do |date|
          entry = calendar_entries.find { |e| e.date == date }
          rates = Concierge::SafeAccessHash.new(rate)

          nightly_rate = rates.get("per_person.1")

          if entry
            entry.nightly_rate = nightly_rate
          else
            calendar_entries << Roomorama::Calendar::Entry.new(
              date:         date.to_s,
              available:    true,
              nightly_rate: nightly_rate
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
