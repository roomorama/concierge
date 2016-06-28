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
    MAXIMUM_STAY_LENGTH = 15 # days

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    def quote(params)
      return Result.new(unavailable_quotation) if params.stay_length > MAXIMUM_STAY_LENGTH
      JTB::Price.new(credentials).quote(params)
    end

    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      result = JTB::Booking.new(credentials).book(params)
      if result.success?
        Reservation.new(params).tap do |reservation|
          reservation.code = result.value
          database.create(reservation) # workaround to keep booking code for reservation
        end
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
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end

    def unavailable_quotation
      Quotation.new(errors: { quote: "Maximum length of stay must be less than #{MAXIMUM_STAY_LENGTH} nights." })
    end

  end
end
