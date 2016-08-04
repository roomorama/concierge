module Poplidays

  # +Poplidays::Client+
  #
  # This class is a convenience class for the smaller classes under +Poplidays+.
  # For now, it allows the caller to get price quotations.
  #
  # For more information on how to interact with Poplidays, check the project Wiki.
  class Client
    SUPPLIER_NAME = "Poplidays"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote prices
    #
    # If an error happens in any step in the process of getting a response back from
    # Poplidays, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = Poplidays::Client.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      Poplidays::Price.new(credentials).quote(params)
    end

    # Returns a +Result+ wrapping +Reservation+ in success case.
    # If an error happens in any step in the process of getting a response back from
    # Poplidays, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      Poplidays::Booking.new(credentials).book(params).tap do |reservation|
        database.create(reservation.value) if reservation.success?
      end
    end

    private

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end
  end

end
