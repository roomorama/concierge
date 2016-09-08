module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "RentalsUnited"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Quote RentalsUnited properties prices
    # If an error happens in any step in the process of getting a response back
    # from RentalsUnited, a result object with error is returned
    #
    # Usage
    #
    #   comamnd = RentalsUnited::Client.new(credentials)
    #   result = command.quote(params)
    #
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ with +Result::Error+ when operation fails
    def quote(quotation_params)
      command = RentalsUnited::Commands::QuotationFetcher.new(
        credentials,
        quotation_params
      )
      command.call
    end
  end
end
