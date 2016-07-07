module Poplidays

  # +Poplidays::Client+
  #
  # This class is a convenience class for the smaller classes under +Poplidays+.
  # For now, it allows the caller to get price quotations.
  #
  # For more information on how to interact with Poplidays, check the project Wiki.
  class Client
    SUPPLIER_NAME = "Poplidays"

    # Quote prices
    #
    # If an error happens in any step in the process of getting a response back from
    # Poplidays, a generic error message is sent back to the caller, and the failure
    # is logged.
    #
    # Usage
    #
    #   result = Poplidays::Client.new(credentials).quote(stay_params)
    #   if result.success?
    #     # ...
    #   end
    #
    # Returns a +Result+ wrapping a +Quotation+ when operation succeeds
    # Returns a +Result+ wrapping a nil object when operation fails
    def quote(params)
      Poplidays::Price.new.quote(params)
    end

    private

    def announce_error(operation, result)
      Concierge::Announcer.trigger(Concierge::Errors::EXTERNAL_ERROR, {
        operation:   operation,
        supplier:    SUPPLIER_NAME,
        code:        result.error.code,
        context:     Concierge.context.to_h,
        happened_at: Time.now
      })
    end
  end

end
