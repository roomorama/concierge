module Ciirus
  module Mappers
    # +Ciirus::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from Ciirus API.
    class RoomoramaCalendar

      # Maps Ciirus API responses to +Roomorama::Calendar+
      # Every rate defines availability period with daily price.
      # Every reservation defines reservation period.
      # So available dates are rates dateranges - reservation dateranges.
      # Rates with 0 price are not valid.
      #
      # Arguments
      #
      #   * +propertyid+ [String]
      #   * +rates+ [Array] array of Ciirus::Entities::PropertyRate
      #   * +reservations+ [Array] array of Ciirus::Entities::Reservation
      def build(property_id, rates, reservations)
        calendar = Roomorama::Calendar.new(property_id)

        entries = build_entries(rates, reservations)
        entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private

      def build_entries(rates, reservations)
        reservations_index = build_reservations_index(reservations)
        entries = []
        today = Date.today
        rates.each do |rate|

          next if rate.daily_rate == 0

          (rate.from_date..rate.to_date).each do |date|

            next if date <= today
            available = !date_reserved?(date, reservations_index)
            entries << Roomorama::Calendar::Entry.new(
              date:             date.to_s,
              available:        available,
              nightly_rate:     rate.daily_rate,
              checkin_allowed:  available
            )
          end
        end
        entries
      end

      def date_reserved?(date, reservations_index)
        reservation = reservations_index[date]
        !reservation.nil? && reservation.departure_date != date
      end

      def build_reservations_index(reservations)
        {}.tap do |i|
          reservations.each do |r|
            (r.arrival_date..r.departure_date).each { |d| i[d] = r }
          end
        end
      end
    end
  end
end
