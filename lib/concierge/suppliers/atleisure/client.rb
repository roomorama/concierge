module AtLeisure

  # +AtLeisure::Client+
  #
  # This class is a convenience class for the smaller classes under +AtLeisure+.
  # For now, it allows the caller to get price quotations and create booking.
  #
  # Usage
  #
  #   quotation = AtLeisure::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with AtLeisure, check the project Wiki.
  class Client
    SUPPLIER_NAME = "AtLeisure"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      AtLeisure::Price.new(credentials).quote(params)
    end

    # Always returns a +Reservation+.
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      result = AtLeisure::Booking.new(credentials).book(params)
      database.create(result.value) if result.success? # workaround to keep booking code for reservation
      result
    end

    private

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end

  end

end
