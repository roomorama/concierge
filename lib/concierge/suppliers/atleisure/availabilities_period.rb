module AtLeisure
  class AvailabilityPeriod

    attr_reader :check_in, :check_out, :price

    def initialize(period)
      @check_in = Date.parse(period['ArrivalDate'])
      @check_out = Date.parse(period['DepartureDate'])
      @price = period['Price'].to_f
    end

    def dates
      (check_in..check_out).to_a
    end

    def daily_price
       price / dates.size
    end

    def valid?
      check_in > Date.today
    end
  end
end