module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Calendar+
    #
    # This class is responsible for building a calendar for property.
    class Calendar
      attr_reader :property_id, :seasons, :availabilities

      CHECK_IN_ALLOWED_CHANGEOVER_TYPE_IDS  = [1, 4]
      CHECK_OUT_ALLOWED_CHANGEOVER_TYPE_IDS = [2, 4]

      # Initialize +RentalsUnited::Mappers::Calendar+
      #
      # Arguments
      #
      #   * +propertyid+ [String] id of property
      #   * +seasons+ [Array<Entities::Season>] seasons
      #   * +availabilities+ [Array<Entities::Availability>] availabilities
      def initialize(property_id, seasons, availabilities)
        @property_id    = property_id
        @seasons        = seasons
        @availabilities = availabilities
      end

      # Builds calendar.
      #
      # Returns [Roomorama::Calendar] property calendar object
      def build_calendar
        calendar = Roomorama::Calendar.new(property_id)

        entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private
      def entries
        availabilities.map do |availability|
          nightly_rate = rate_by_date(availability.date)

          if nightly_rate.zero?
            available = false
            checkin_allowed = false
            checkout_allowed = false
          else
            available = availability.available
            checkin_allowed  = checkin_allowed?(availability.changeover)
            checkout_allowed = checkout_allowed?(availability.changeover)
          end

          Roomorama::Calendar::Entry.new(
            date:             availability.date.to_s,
            available:        available,
            nightly_rate:     nightly_rate,
            minimum_stay:     availability.minimum_stay,
            checkin_allowed:  checkin_allowed,
            checkout_allowed: checkout_allowed
          )
        end
      end

      def rate_by_date(date)
        season = seasons.find { |s| s.has_price_for_date?(date) }
        season&.price.to_f
      end

      def checkin_allowed?(changeover)
        CHECK_IN_ALLOWED_CHANGEOVER_TYPE_IDS.include?(changeover)
      end

      def checkout_allowed?(changeover)
        CHECK_OUT_ALLOWED_CHANGEOVER_TYPE_IDS.include?(changeover)
      end
    end
  end
end
