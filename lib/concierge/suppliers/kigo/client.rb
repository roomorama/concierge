module Kigo

  # +Kigo::Client+
  #
  # This class is a convenience class for the smaller classes under +Kigo+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = Kigo::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Kigo, check the project Wiki.
  # Note that this client interacts with the new Kigo Channels API. For
  # reference of the old Kigo API, check +Kigo::Legacy+.
  class Client
    SUPPLIER_NAME = "Kigo"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # Kigo, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      result = Kigo::Price.new(credentials).quote(params)

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
