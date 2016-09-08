module RentalsUnited
  # +RentalsUnited::Client+
  class Client
    SUPPLIER_NAME = "rentals_united"

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end
  end
end
