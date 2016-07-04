module Ciirus
  #  +Ciirus::Client+
  #
  # This class is a convenience class for the smaller classes under +Ciirus+
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = Ciirus::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Ciirus, check the project Wiki.
  class Client
    SUPPLIER_NAME = 'Ciirus'

    attr_reader :credentials

    def initialize(creadentials)
      @credentials = creadentials
    end

    # Returns a +Result+ wrapping +Quotation+ in success case.
    # If an error happens in any step in the process of getting a response back from
    # Ciirus, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      Ciirus::Commands::QuoteFetcher.new(credentials).call(params)
    end

    # Returns a +Result+ wrapping +Reservation+ in success case.
    # If an error happens in any step in the process of getting a response back from
    # Ciirus, a generic error message is sent back to the caller, and the failure
    # is logged.
    def book(params)
      Ciirus::Commands::Booking.new(credentials).call(params)
      database.create(result.value) if result.success? # workaround to keep booking code for reservation
      result
    end

    private

    def database
      @database ||= Concierge::OptionalDatabaseAccess.new(ReservationRepository)
    end

  end
end