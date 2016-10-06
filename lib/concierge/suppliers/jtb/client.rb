module JTB
  # +JTB::Client+
  #
  # This class is a convenience class for the smaller classes under +JTB+.
  # For now, it allows the caller to get price quotations.
  #
  # For more information on how to interact with JTB, check the project Wiki.
  class Client
    SUPPLIER_NAME = "JTB"
    MAXIMUM_STAY_LENGTH = 15 # days

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote prices
    #
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = JTB::Client.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      return stay_too_long_error if params.stay_length > MAXIMUM_STAY_LENGTH
      JTB::Price.new(credentials).quote(params)
    end

    # Property bookings
    #
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = JTB::Client.new(credentials).book(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds.
    def book(params)
      result = JTB::Booking.new(credentials).book(params)
      if result.success?
        reservation = Reservation.new(params).tap do |res|
          res.reference_number = result.value
        end

        Result.new(reservation)
      else
        result
      end
    end

    private

    def stay_too_long_error
      message = "Maximum length of stay must be less than #{MAXIMUM_STAY_LENGTH} nights."
      Result.error(:stay_too_long, message)
    end

  end
end
