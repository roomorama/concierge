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

    # Cancels a given reservation_id
    #
    # Always returns a +Result+.
    # Augments any error on the request context.
    #
    # Usage
    #
    #   client = Woori::Client.new(credentials)
    #   result = client.cancel(params)
    #
    #   if result.sucess?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +String+ with booking id number when
    # operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def cancel(params)
      command = Woori::Commands::Cancel.new(credentials)
      command.call(params[:reservation_id])
    end
  end
end
