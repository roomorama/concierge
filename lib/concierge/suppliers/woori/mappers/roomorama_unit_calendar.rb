module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaUnitCalendar+
    #
    # This class is responsible for building a +Roomorama::UnitCalendar+
    # object.
    class RoomoramaUnitCalendar
      attr_reader :safe_hash

      # Initialize RoomoramaUnitCalendar mapper
      #
      # Arguments:
      #
      #   * +safe_hash+ [Concierge::SafeAccessHash] availability parameters
      def initialize(safe_hash)
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
        return nil unless days && days.any?

        calendar = Roomorama::Calendar.new("id1")
        calendar
      end

      private
      def days
        @days ||= safe_hash.get("data")
      end

      def nightly_rate
        @nightly_rate ||= (monthly_rate / days.size).to_i
      end

      def monthly_rate
        @monthly_rate ||= days.inject(0) { |sum, day| sum + day["price"].to_i }
      end
    end
  end
end
