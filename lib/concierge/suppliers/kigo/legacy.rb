module Kigo

  # +Kigo::Legacy+
  #
  # This class is a client for the Kigo Legacy API. While it holds a lot of
  # similarity with the new Kigo Channels API, some properties can only
  # be queried against the old endpoints.
  #
  # For more information on how to interact with Kigo Channels API and the Kigo
  # Legacy API, check the project Wiki.
  class Legacy
    SUPPLIER_NAME = "Kigo Legacy"

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
    #   result = Kigo::Legacy.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      Kigo::Price.new(credentials, request_handler: request_handler).quote(params)
    end

    # Returns a +Result+ wrapping a +Reservation+.
    # Returns a +Result+ with error if booking fails.
    # Uses an instance +Kigo::LegacyRequest+ to dictate parameters and endpoints.
    def book(params)
      Kigo::Booking.new(credentials, request_handler: request_handler).book(params)
    end

    private

    def request_handler
      LegacyRequest.new(credentials, Kigo::Request.new(credentials))
    end
  end

end
