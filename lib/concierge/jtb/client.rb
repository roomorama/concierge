module JTB
  # +JTB::Client+
  #
  # This class is a convenience class for the smaller classes under +JTB+.
  # For now, it allows the caller to get price quotations.
  #
  # Usage
  #
  #   quotation = JTB::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with JTB, check the project Wiki.
  class Client

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Always returns a +Quotation+.
    # If an error happens in any step in the process of getting a response back from
    # JTB, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      result = JTB::Price.new(credentials).quote(params)

      if result.success?
        result.value
      else
        Quotation.new(errors: { quote: "Could not quote price with remote supplier" })
      end
    end

  end
end