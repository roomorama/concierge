module Poplidays

  # +Poplidays::Client+
  #
  # This class is a convenience class for the smaller classes under +Poplidays+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = Poplidays::Client.new.quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Poplidays, check the project Wiki.
  class Client
    SUPPLIER_NAME = "Poplidays"

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # AtLeisure, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      result = Poplidays::Price.new.quote(params)

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
        message:     result.error.message,
        happened_at: Time.now
      })
    end
  end

end
