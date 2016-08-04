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
  end
end
