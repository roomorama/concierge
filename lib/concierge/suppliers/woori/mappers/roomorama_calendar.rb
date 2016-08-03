module Woori
  module Mappers
    # +Woori::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object.
    class RoomoramaCalendar
      attr_reader :safe_hash

      # Initialize RoomoramaCalendar mapper
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
      #   Mappers::RoomoramaCalendar.build_calendar(safe_hash)
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
