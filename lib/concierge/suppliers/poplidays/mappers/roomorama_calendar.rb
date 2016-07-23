module Poplidays
  module Mappers
    # +Poplidays::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from Poplidays API.
    class RoomoramaCalendar

      # Maps Poplidays API responses to +Roomorama::Calendar+
      # Poplidays has an price/availability for each checkin/checkout pair, called `stay`
      # Some stays are booked on request only or has to be price-quoted via Poplidays CS;
      # we shall consider those stays as not available.
      #
      # Arguments
      #
      #   * +property_id+ [String] property id
      #   * +details+ [Hash] property details
      #   * +availabilities_hash+ [Hash] contains `availabilities` key
      def build(property_id, details, availabilities_hash)
        availabilities = availabilities_hash['availabilities']

        calendar = Roomorama::Calendar.new(property_id)

        entries = build_entries(details, availabilities)
        entries.each { |entry| calendar.add(entry) }

        calendar
      end

      private

      # Prepares each stay from availabilities (parses dates, add useful fields)
      # and build index by dates.
      #
      # Returns a hash:
      #
      # {
      #   date1 => [all stays including the date1],
      #   date2 => [all stays including the date2]
      #   ...
      # }
      def prepare_availabilities(availabilities, mandatory_service_price)
        prepared_availabilities = availabilities.select do |stay|
          !stay['requestOnly'] && stay['priceEnabled']
        end.map do |stay|
          stay.dup.tap do |s|
            from = Date.parse(s['arrival'])
            to = Date.parse(s['departure'])
            s['arrival'] = from
            s['departure'] = to
            s['length'] = (to - from).to_i
            subtotal = mandatory_service_price + s['price']
            s['daily_price'] = (subtotal.to_f / s['length']).round(2)
          end
        end
        Hash.new { |h, key| h[key] = [] }
          .tap do |i|
            prepared_availabilities.each do |s|
              (s['arrival']..s['departure']).each do |date|
                i[date] << s
              end
            end
          end
      end

      def build_entries(details, availabilities)
        entries = []
        max_date = availabilities.map { |s| Date.parse(s['departure']) }.max
        mandatory_services = details['mandatoryServicesPrice']
        prepared_availabilities = prepare_availabilities(availabilities, mandatory_services)
        tomorrow = Date.today + 1

        (tomorrow..max_date).each do |date|
          if prepared_availabilities.key?(date)
            date_availabilities = prepared_availabilities[date]
            checkin_allowed = date_availabilities.any? { |s| s['arrival'] == date }
            checkout_allowed = date_availabilities.any? { |s| s['departure'] == date }
            daily_rate = date_availabilities.map { |s| s['daily_price'] }.min
            entry = Roomorama::Calendar::Entry.new(
              date:             date.to_s,
              nightly_rate:     daily_rate,
              available:        true,
              checkin_allowed:  checkin_allowed,
              checkout_allowed: checkout_allowed,
            )
            if checkin_allowed
              min_stay = date_availabilities.map { |s| s['length'] }.min
              entry.minimum_stay = min_stay
            end
          else
            # If date isn't inside any availability's range the date is unavailable
            entry = Roomorama::Calendar::Entry.new(
              date:             date.to_s,
              nightly_rate:     0,
              available:        false,
              checkin_allowed:  false,
              checkout_allowed: false
            )
          end
          entries << entry
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