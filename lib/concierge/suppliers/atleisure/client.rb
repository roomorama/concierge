module AtLeisure

  # +AtLeisure::Client+
  #
  # This class is a convenience class for the smaller classes under +AtLeisure+.
  # For now, it allows the caller to get price quotations and create booking.
  #
  # For more information on how to interact with AtLeisure, check the project Wiki.
  class Client
    SUPPLIER_NAME = "AtLeisure"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote prices
    #
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = AtLeisure::Client.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      AtLeisure::Price.new(credentials).quote(params)
    end

    # Property bookings
    #
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = AtLeisure::Client.new(credentials).book(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
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
