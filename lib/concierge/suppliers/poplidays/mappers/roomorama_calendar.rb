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
        availabilities = Array(availabilities_hash['availabilities'])
        entries = build_entries(details, availabilities)

        Roomorama::Calendar.new(property_id).tap do |c|
          entries.each { |entry| c.add(entry) }
        end
      end

      private

      def build_entries(details, availabilities)
        mandatory_services = details['mandatoryServicesPrice'].to_f
        stays = availabilities.select do |a|
          availability_validator(a).valid?
        end.map do |a|
          Roomorama::Calendar::Stay.new({
            checkin:   a['arrival'],
            checkout:  a['departure'],
            price:     mandatory_services + a['price'],
            available: true
          })
        end
        Roomorama::Calendar::StaysMapper.new(stays, Date.today).map
      end

      def availability_validator(availability)
        Poplidays::Validators::AvailabilityValidator.new(availability)
      end
    end
  end
end