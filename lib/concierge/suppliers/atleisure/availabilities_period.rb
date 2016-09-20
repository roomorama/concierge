module AtLeisure
  # +AtLeisure::AvailabilityPeriod+
  #
  # This class represents supplier's availabilities in period range format
  class AvailabilityPeriod

    attr_reader :check_in, :check_out, :price

    def initialize(period)
      @check_in   = Date.parse(period['ArrivalDate'])
      @check_out  = Date.parse(period['DepartureDate'])
      @price      = period['Price'].to_f
    end

    def dates
      (check_in..check_out).to_a
    end

    def nights
      (check_out - check_in).to_i
    end

    def daily_price
      price / dates.size
    end
  end
end