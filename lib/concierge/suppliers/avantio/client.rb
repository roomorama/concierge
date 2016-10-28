module Avantio
  #  +Avantio::Client+
  #
  # This class is a convenience class for the smaller classes under +Avantio+
  #
  # Usage
  #
  #   quotation = Avantio::Client.new(credentials).quote(stay_params)
  #   if quotation.sucessful?
  #     # ...
  #   end
  #
  # For more information on how to interact with Avantio, check the project Wiki.
  class Client
    SUPPLIER_NAME = 'Avantio'

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # Returns a +Result+ wrapping +Quotation+ in success case.
    # If an error happens in any step in the process of getting a response back from
    # Avantio, a generic error message is sent back to the caller, and the failure
    # is logged.
    def quote(params)
      Avantio::Price.new(credentials).quote(params)
    end
  end
end