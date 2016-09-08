module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Calendar+
    #
    # This class is responsible for building a calendar for property.
    class Calendar
      attr_reader :property_id, :rates, :availabilities

      # Initialize +RentalsUnited::Mappers::Calendar+
      #
      # Arguments
      #
      #   * +propertyid+ [String] id of property
      #   * +rates+ [Array<Entities::Rate>] rates
      #   * +availabilities+ [Array<Entities::Availability>] availabilities
      def initialize(property_id, rates, availabilities)
        @property_id    = property_id
        @rates          = rates
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
            date:         availability.date.to_s,
            available:    availability.available,
            nightly_rate: rate_by_date(availability.date),
            minimum_stay: availability.minimum_stay
          )
        end
      end

      def rate_by_date(date)
        rates.each do |rate|
          return rate.price if rate.has_price_for_date?(date)
        end

        return nil
      end
    end
  end
end
