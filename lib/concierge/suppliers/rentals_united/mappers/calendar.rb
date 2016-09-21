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

        valid_entries = entries.select { |entry| entry.valid? }
        valid_entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private
      def entries
        availabilities.map do |availability|
          Roomorama::Calendar::Entry.new(
            date:             availability.date.to_s,
            available:        availability.available,
            nightly_rate:     rate_by_date(availability.date),
            minimum_stay:     availability.minimum_stay,
            checkin_allowed:  checkin_allowed?(availability.changeover),
            checkout_allowed: checkout_allowed?(availability.changeover)
          )
        end
      end

      def rate_by_date(date)
        season = seasons.find { |s| s.has_price_for_date?(date) }
        season&.price
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
