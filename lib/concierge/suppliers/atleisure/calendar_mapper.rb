module AtLeisure
  module Mappers
    # +AtLeisure::Mappers::Calendar+
    #
    # This class is responsible for building a +Roomorama::Calendar+ object
    # from data getting from AtLeisure API.
    class Calendar

      # Maps AtLeisure API responses to +Roomorama::Calendar+
      # AtLeisure has an price/availability for each checkin/checkout pair, called `stay`
      # Some stays are booked on request only, we shall consider those stays as not available.
      #
      # Arguments
      #
      #   * +availabilities+ [Hash] response from AtLeisure API
      #
      #  Returns +Result+ wrapping +Roomorama::Calendar+ in success case
      def build(availabilities)
        today = Date.today
        property_id = availabilities['HouseCode']

        stays = Array(availabilities['AvailabilityPeriodV1']).select { |availability|
          validator(availability, today).valid?
        }.map { |availability| to_stay(availability) }

        build_calendar(property_id, stays, today)
      end

      private

      def validator(availability, today)
        ::AtLeisure::AvailabilityValidator.new(availability, today)
      end

      def to_stay(availability)
        Roomorama::Calendar::Stay.new({
          checkin:    availability['ArrivalDate'],
          checkout:   availability['DepartureDate'],
          price:      availability['Price'].to_f,
        })
      end

      def build_calendar(property_id, stays, today)
        calendar = Roomorama::Calendar.new(property_id).tap do |c|
          entries = Roomorama::Calendar::StaysMapper.new(stays, today).map
          entries.each { |entry| c.add(entry) }
        end

        Result.new(calendar)
      end
    end
  end
end
