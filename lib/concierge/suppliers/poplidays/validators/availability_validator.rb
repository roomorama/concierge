module Poplidays
  module Validators
    # +Poplidays::Validators::AvailabilityValidator+
    #
    # This class responsible for property availability validation.
    # cases when availability is invalid:
    #
    #   * stay is on request only
    #   * property price is only available through call center
    #
    class AvailabilityValidator
      attr_reader :availability

      # availability is a hash representation of each element
      # from availabilities collection of Poplidays availabilies response
      def initialize(availability)
        @availability = availability
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
    end
  end
end