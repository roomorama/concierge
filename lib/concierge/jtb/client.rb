module JTB
  # +JTB::Client+
  #
  # This class is a convenience class for the smaller classes under +JTB+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = JTB::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with JTB, check the project Wiki.
  class Client
    SUPPLIER_NAME = "JTB"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      result = JTB::Price.new(credentials).quote(params)

      if result.success?
        result.value
      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      result = JTB::Booking.new(credentials).book(params)
      if result.success?
        reservation = Reservation.new(params)
        reservation.code = result.value
        reservation
      else
        announce_error("booking", result)
        Reservation.new(errors: { booking: 'Could not book property with remote supplier' })
      end
    end

    private

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        message:     result.error.message,
        happened_at: Time.now
      })
    end

  end
end
