module Avantio
  module Mappers
    # +Avantio::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from Avantio.
    class RoomoramaCalendar
      # Maps Avantio data to +Roomorama::Calendar+
      #
      # Arguments
      #
      #   * +propertyid+ [String]
      #   * +rate+ [Avantio::Entities::Rate]
      #   * +availability+ [Avantio::Entities::Availability]
      #   * +rule+ [Avantio::Entities::Rule]
      #   * +length+ [Fixnum] all operations (calc of min_stay, calc of nightly_rate)
      #                       will be in daterange from today to today + length
      def build(property_id, rate, availability, rule, length)
        calendar = Roomorama::Calendar.new(property_id)

        entries = build_entries(rate, availability, rule, length)
        entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private

      def calendar_start
        Date.today
      end

      def calendar_end(length)
        calendar_start + length
      end

      def fill_availability(availability, length)
        {}.tap do |result|
          availability.actual_periods(length).each do |period|
            from = [calendar_start, period.start_date].max
            to = [calendar_end(length), period.end_date].min
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

      def fill_rates!(entries, rate, length)
        rate.actual_periods(length).each do |period|
          from = [calendar_start, period.start_date].max
          to = [calendar_end(length), period.end_date].min
          (from..to).each do |date|
            entry = entries[date]
            entry.nightly_rate = period.price if entry
          end
        end
      end

      def fill_checkin_checkout!(entries, rule, length)
        rule.actual_seasons(length).each do |season|
          from = [calendar_start, season.start_date].max
          to = [calendar_end(length), season.end_date].min
          (from..to).each do |date|
            entry = entries[date]
            entry.mininum_stay = season.min_nights_online || season.min_nights
            entry.check_in_allowed = season.check_in_allowed(date)
            entry.check_out_allowed = season.check_out_allowed(date)
          end
        end
      end

      def build_entries(rate, availability, rule, length)
        entries = fill_availability(availability, length)
        fill_rates!(entries, rate, length)
        fill_min_nights_checkin_checkout!(entries, rule, length)
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
