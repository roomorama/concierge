module Woori
  module Commands
    # +Woori::Commands::CalendarFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # property calendar from Woori, parsing the response, and building a
    # +Result+ which wraps +Roomorama::Calendar+ object.
    class CalendarFetcher < BaseFetcher
      include Concierge::JSON

      ENDPOINT = "available"

      # Retrieves availabilities for property and builds calendar
      #
      # Arguments
      #
      #   * +property+ [Property] property to fetch calendar for
      #
      # Usage
      #
      #   command = Woori::Commands::CalendarFetcher.new(credentials)
      #   result = command.call(property)
      #
      # Returns a +Result+ wrapping +Roomorama::Calendar+ object
      # when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call(property)
        calendar = Roomorama::Calendar.new(property.identifier)

        units = Array(property.data["units"])
        units.each do |unit|
          calendar_result = fetch_and_build_unit_calendar(unit["identifier"])

          return calendar_result unless calendar_result.success?

          calendar.add_unit(calendar_result.value)
        end

        Result.new(calendar)
      end

      private
      def fetch_and_build_unit_calendar(unit_id)
        params = build_request_params(unit_id)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)

          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            mapper = Woori::Mappers::RoomoramaUnitCalendar.new(
              unit_id,
              safe_hash
            )
            Result.new(mapper.build_calendar)
          else
            decoded_result
          end
        else
          result
        end
      end

      def build_request_params(unit_id)
        current_date = Time.now

        {
          roomCode: unit_id,
          searchStartDate: current_date.strftime("%Y-%m-%d"),
          searchEndDate: (current_date + 30 * 60 * 60 * 24).strftime("%Y-%m-%d")
        }
      end
    end
  end
end
