module SAW
  # +SAW::Client+
  #
  # This class is a convenience class for the smaller classes under +SAW+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = SAW::Client.new(credentials).quote(params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with SAW, check the project Wiki.
  class Client
    SUPPLIER_NAME = "SAW"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back
    # from SAW, a generic error message is sent back to the caller, and the
    # failure is logged.
    def quote(params)
      result = SAW::Price.new(credentials).quote(params)

      if result.success?
        result.value
      else
        announce_error(:quote, result)
        error_quotation
      end
    end

    private
    def error_quotation
      Quotation.new(
        errors: { quote: "Could not quote price with remote supplier" }
      )
    end
    
    def announce_error(operation, result)
      info = {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        message:     result.error.data,
        happened_at: Time.now
      }
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, info)
    end
  end
end
