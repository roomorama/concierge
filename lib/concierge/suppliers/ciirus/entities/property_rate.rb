module Ciirus
  module Entities
    class PropertyRate
      attr_reader :from_date, :to_date, :min_nights_stay, :daily_rate

      def initialize(from_date, to_date, min_nights_stay, daily_rate)
        @from_date = from_date
        @to_date = to_date
        @min_nights_stay = min_nights_stay
        @daily_rate = daily_rate
      end

      def ==(other)
        self.class == other.class && state == other.state
      end

      protected

      def state
        [from_date, to_date, min_nights_stay, daily_rate]
      end
    end
  end
end