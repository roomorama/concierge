module Woori
  module Commands
    # +Woori::Commands::UnitCalendarFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # unit calendar from Woori, parsing the response, and building a
    # +Result+ which wraps +Roomorama::Calendar+ object.
    class UnitCalendarFetcher < BaseFetcher
      include Concierge::JSON

      ENDPOINT = "available"

      # Retrieves availabilities for unit by unit_id and builds calendar
      #
      # Arguments
      #
      #   * +unit_id+ [String] unit id (room code hash)
      #
      # Usage
      #
      #   command = Woori::Commands::UnitCalendarFetcher.new(credentials)
      #   result = command.call("w_w0104006")
      #
      # Returns a +Result+ wrapping +Roomorama::Calendar+ object
      # when operation succeeds
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call(unit_id)
        params = build_request_params(unit_id)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)

          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)
            mapper = Woori::Mappers::RoomoramaCalendar.new(safe_hash)
            calendar = mapper.build_calendar
            Result.new(calendar)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
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
