module SAW
  class Client
    SUPPLIER_NAME = "SAW"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # returns Quotation object (for both success and fail cases)
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
