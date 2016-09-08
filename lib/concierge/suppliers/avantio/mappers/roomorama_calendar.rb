module Avantio
  module Mappers
    # +Avantio::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from Avantio.
    class RoomoramaCalendar

      # Count of days from today
      PERIOD_SYNC = 365

      # Maps Avantio data to +Roomorama::Calendar+
      #
      # Arguments
      #
      #   * +propertyid+ [String]
      #   * +rate+ [Avantio::Entities::Rate]
      #   * +availability+ [Avantio::Entities::Availability]
      #   * +rule+ [Avantio::Entities::Rule]
      def build(property_id, rate, availability, rule)
        calendar = Roomorama::Calendar.new(property_id)

        entries = build_entries(rate, availability, rule)
        entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private

      def calendar_start
        Date.today
      end

      def calendar_end
        calendar_start + PERIOD_SYNC
      end

      def fill_availability(availability)
        {}.tap do |result|
          availability.actual_periods(PERIOD_SYNC).each do |period|
            from = [calendar_start, period.start_date].max
            to = [calendar_end, period.end_date].min
            available = period.available?
            (from..to).each do |date|
              result[date] = Roomorama::Calendar::Entry.new(
                date:         date.to_s,
                available:    available,
              )
            end
          end
        end
      end

      def fill_rates!(result, rate)
        rate.actual_periods.each do |period|
          from = [calendar_start, period.start_date].max
          to = [calendar_end, period.end_date].min
          (from..to).each do |date|
            entry = result[date]
            entry.nightly_rate = period.price if entry
          end
        end
      end

      def fill_checkin_checkout!(result, rule)

      end

      def build_entries(rate, availability, rule)
        result = fill_availability(availability)
        fill_rates!(result, rate)
        fill_checkin_checkout!(result, rule)

        reservations_index = build_reservations_index(reservations)
        entries = []
        today = Date.today
        rates.each do |rate|

          (rate.from_date..rate.to_date).each do |date|

            next if date <= today
            break if date > today + PERIOD_SYNC

            if rate.daily_rate == 0
              entry = Roomorama::Calendar::Entry.new(
                date:             date.to_s,
                available:        false,
                nightly_rate:     0
              )
            else
              available = !date_reserved?(date, reservations_index)
              entry = Roomorama::Calendar::Entry.new(
                date:              date.to_s,
                available:         available,
                nightly_rate:      rate.daily_rate,
                minimum_stay:      rate.min_nights_stay
              )
            end
            entries << entry
          end
        end
        entries
      end

      def date_reserved?(date, reservations_index)
        reservation = reservations_index[date]
        reservation && reservation.departure_date != date
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
