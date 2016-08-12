module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaUnitCalendar+
    #
    # This class is responsible for building a +Roomorama::UnitCalendar+
    # object.
    class RoomoramaUnitCalendar
      attr_reader :unit_id, :safe_hash

      # Initialize RoomoramaUnitCalendar mapper
      #
      # Arguments:
      #
      #   * +unit_id+ [String] unit id
      #   * +safe_hash+ [Concierge::SafeAccessHash] availability parameters
      def initialize(unit_id, safe_hash)
        @unit_id = unit_id
        @safe_hash = safe_hash
      end

      # Builds Roomorama::Calendar object
      #
      # Usage:
      #
      #   mapper = Mappers::RoomoramaUnitCalendar.new(hash)
      #   mapper.build_calendar
      #
      # Returns +Roomorama::Calendar+ Unit calendar object
      def build_calendar
        return nil unless raw_entries && raw_entries.any?

        unit_calendar = Roomorama::Calendar.new(unit_id)
        unit_calendar_entries.each do |entry|
          unit_calendar.add(entry)
        end

        unit_calendar
      end

      private
      def raw_entries
        @days ||= safe_hash.get("data")
      end

      def unit_calendar_entries
        raw_entries.map { |hash| build_unit_calendar_entry(hash) }
      end

      def build_unit_calendar_entry(hash)
        date = Date.parse(hash["date"]).to_s
        available = hash["vacancy"].to_i > 0 && hash["isActive"].to_i == 1
        nightly_rate = hash["price"]

        Roomorama::Calendar::Entry.new(
          date:         date,
          available:    available,
          nightly_rate: nightly_rate
        )
      end
    end
  end
end
