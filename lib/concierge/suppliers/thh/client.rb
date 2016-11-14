module THH
  #  +THH::Client+
  #
  # This class is a convenience class for the smaller classes under +THH+.
  # For now, it allows the caller to get price quotations.
  #
  # For more information on how to interact with THH, check the project Wiki.
  class Client
    SUPPLIER_NAME = 'THH'

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def quote(params)
      THH::Price.new(credentials).quote(params)
    end

    def book(params)
      THH::Booking.new(credentials).book(params)
    end

    def cancel(params)
      THH::Commands::Cancel.new(credentials).call(params[:reference_number])
    end
  end
end
