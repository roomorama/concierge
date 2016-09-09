module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "RentalsUnited"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # RentalsUnited properties booking.
    #
    # If an error happens in any step in the process of getting a response back
    # from RentalsUnited, a result object with error is returned
    #
    # Usage
    #
    #   comamnd = RentalsUnited::Client.new(credentials, reservation_params)
    #   result = command.book
    #
    #   if result.sucess?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def book(reservation_params)
      command = RentalsUnited::Commands::Booking.new(
        credentials,
        reservation_params
      )
      command.call
    end
  end
end
