module Woori

  # +Woori::Client+
  #
  # This class is a convenience class for the smaller classes under +Woori+.
  #
  # For more information on how to interact with Woori, check the project Wiki.
  class Client
    SUPPLIER_NAME = "Woori"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end
    
    # Quote Woori properties prices
    # If an error happens in any step in the process of getting a response back
    # from Woori, a result object with error is returned  
    #
    # Usage
    #
    #   comamnd = Woori::Client.new(credentials)
    #   result = command.quote(params)
    #
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def quote(params)
      command = Woori::Commands::QuotationFetcher.new(credentials)
      command.call(params)
    end
    
    # Woori properties booking.
    #
    # If an error happens in any step in the process of getting a response back
    # from Woori, a result object with error is returned
    #
    # Usage
    #
    #   comamnd = Woori::Client.new(credentials)
    #   result = command.book(params)
    #
    # Returns a +Result+ wrapping a +Reservation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def book(params)
      command = Woori::Commands::Booking.new(credentials)
      command.call(params)
    end

    # Cancels a given reference_number
    #
    # Always returns a +Result+.
    # Augments any error on the request context.
    #
    # Usage
    #
    #   client = Woori::Client.new(credentials)
    #   result = client.cancel(params)
    #
    # Returns a +Result+ wrapping a +String+ with booking id number when
    # operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def cancel(params)
      command = Woori::Commands::Cancel.new(credentials)
      command.call(params[:reference_number])
    end
  end
end
