module Kigo

  # +Kigo::Client+
  #
  # This class is a convenience class for the smaller classes under +Kigo+.
  # For now, it allows the caller to get price quotations.
  #
  # For more information on how to interact with Kigo, check the project Wiki.
  # Note that this client interacts with the new Kigo Channels API. For
  # reference of the old Kigo API, check +Kigo::Legacy+.
  class Client
    SUPPLIER_NAME = "Kigo"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote prices
    # 
    # If an error happens in any step in the process of getting a response back from
    # Kigo, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = Kigo::Client.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      Kigo::Price.new(credentials).quote(params)
    end

    # Returns a +Result+ wrapping a +Reservation+.
    # Returns a +Result+ with error if booking fails.
    # Uses an instance +Kigo::Request+ to dictate parameters and endpoints.
    def book(params)
      Kigo::Booking.new(credentials).book(params)
    end
  end

end
