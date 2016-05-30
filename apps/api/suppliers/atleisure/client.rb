module AtLeisure

  # +AtLeisure::Client+
  #
  # This class is a convenience class for the smaller classes under +AtLeisure+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = AtLeisure::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with AtLeisure, check the project Wiki.
  class Client
    SUPPLIER_NAME = "AtLeisure"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      result = AtLeisure::Price.new(credentials).quote(params)

      if result.success?
        result.value
      else
        announce_error("quote", result)
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

    private

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     API.context.to_h,
        message:     "DEPRECATED",
        happened_at: Time.now
      })
    end
  end

end
