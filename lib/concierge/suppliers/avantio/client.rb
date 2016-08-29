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

  end
end