module THH
  module Mappers
    # +THH::Mappers::RoomoramaCalendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from THH API.
    class RoomoramaCalendar
      # Arguments
      #
      #   * +property+ [SafeAccessHash] raw property fetched from THH API
      def build(property)
        Roomorama::Calendar.new(property['property_id']).tap do |result|
          entries = build_entries(property)
          entries.each { |entry| result.add(entry) }
        end
      end

      def calendar_start
        Date.today
      end

      def calendar_end
        calendar_start + THH::Mappers::RoomoramaProperty::SYNC_PERIOD
      end

      private

      def build_entries(property)
        rates = Array(property.get('rates.rate'))
        booked_periods = Array(property.get('calendar.periods.period'))

        calendar = THH::Calendar.new(rates, booked_periods, THH::Mappers::RoomoramaProperty::SYNC_PERIOD)

        rates_days = calendar.rates_days
        booked_days = calendar.booked_days

        (calendar_start..calendar_end).map do |date|
          rate = rates_days[date]
          available = rate && !booked_days.include?(date)
          nightly_rate = rate ? rate[:night] : 0

          Roomorama::Calendar::Entry.new(
            date:         date,
            available:    available,
            nightly_rate: nightly_rate,
            minimum_stay: (rate[:min_nights] if rate)
          )
        end
      end
    end
  end
end
