module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "RentalsUnited"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end
  end
end
