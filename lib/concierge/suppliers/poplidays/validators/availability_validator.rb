module Poplidays
  module Validators
    # +Poplidays::Validators::AvailabilityValidator+
    #
    # This class responsible for property availability validation.
    # cases when availability is invalid:
    #
    #   * stay is on request only
    #   * property price is only available through call center
    #   * stay is too old
    class AvailabilityValidator
      attr_reader :availability, :today

      # availability is a hash representation of each element
      # from availabilities collection of Poplidays availabilies response.
      # today is today date, the purpose of the argument to save consistency of more
      # then one availability validation process.
      def initialize(availability, today)
        @availability = availability
        @today = today
      end

      def valid?
        !on_request_only? && price_enabled?
      end

      private

      def on_request_only?
        availability['requestOnly']
      end

      def price_enabled?
        availability['priceEnabled']
      end

      def actual?
        Date.parse(s['arrival']) > today
      end
    end
  end
end