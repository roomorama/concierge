module PriceChecker
  class Base

    attr_reader :property_id, :check_in, :check_out, :num_guests

    def initialize(property_id, check_in, check_out, num_guests)

    end

    def check_stay

    end

    def quote_price

    end

    def room_available?

    end

  end
end