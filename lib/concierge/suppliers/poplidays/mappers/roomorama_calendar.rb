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
        entries = build_entries(details, availabilities)

        Roomorama::Calendar.new(property_id).tap do |c|
          entries.each { |entry| c.add(entry) }
        end
      end

      private

      def build_entries(details, availabilities)
        today = Date.today
        mandatory_services = details['mandatoryServicesPrice']
        stays = availabilities.map do |a|
          Roomorama::Calendar::Stay.new({
            checkin:   a['arrival'],
            checkout:  a['departure'],
            price:     mandatory_services + a['price'],
            available: availability_validator(a, today).valid?
          })
        end
        return [] if stays.empty?
        Roomorama::Calendar::StaysMapper.new(stays, today).map
      end

      def availability_validator(availability, today)
        Poplidays::Validators::AvailabilityValidator.new(availability, today)
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