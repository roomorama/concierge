module Poplidays
  module Validators
    # +Poplidays::Validators::AvailabilitiesValidator+
    #
    # This class responsible for property availabilities validation.
    # cases when availabilities is invalid:
    #
    #   * list of valid availabilities is empty
    #
    class AvailabilitiesValidator
      attr_reader :availabilities, :today

      # availabilities is a hash representation of Poplidays availabilies response
      # today is date, the purpose of the argument to save consistency of more
      # then one availability validation process.
      def initialize(availabilities, today)
        @availabilities = availabilities
        @today = today
      end

      def valid?
        !valid_availabilities.empty?
      end

      private

      def valid_availabilities
        availabilities['availabilities'].select do |availability|
          availability_validator(availability).valid?
        end
      end

      def availability_validator(availability)
        Poplidays::Validators::AvailabilityValidator.new(availability, today)
      end
    end
  end
end