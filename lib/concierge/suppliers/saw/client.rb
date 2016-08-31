module SAW
  # +SAW::Client+
  #
  # This class is a convenience class for the smaller classes under +SAW+.
  #
  # For more information on how to interact with SAW, check the project Wiki.
  class Client
    SUPPLIER_NAME = "SAW"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote SAW properties prices
    # If an error happens in any step in the process of getting a response back
    # from SAW, a result object with error is returned
    #
    # Usage
    #
    #   comamnd = SAW::Client.new(credentials)
    #   result = command.quote(params)
    #
    #   if result.sucess?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def quote(params)
      command = SAW::Commands::PriceFetcher.new(credentials)
      command.call(params)
    end

    # SAW properties booking.
    #
    # If an error happens in any step in the process of getting a response back
    # from SAW, a result object with error is returned
    #
    # Usage
    #
    #   comamnd = SAW::Client.new(credentials)
    #   result = command.book(params)
    #
    #   if result.sucess?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def book(params)
      command = SAW::Commands::Booking.new(credentials)
      command.call(params)
    end

    # Cancels a given reference_number
    #
    # Always returns a +Result+.
    # Augments any error on the request context.
    #
    # Usage
    #
    #   client = SAW::Client.new(credentials)
    #   result = client.cancel(params)
    #
    #   if result.sucess?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +String+ with booking id number when
    # operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def cancel(params)
      command = SAW::Commands::Cancel.new(credentials)
      command.call(params[:reference_number])
    end
  end
end
