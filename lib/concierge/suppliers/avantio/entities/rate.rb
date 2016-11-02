module Avantio
  module Entities
    class Rate
      class Period
        attr_reader :start_date, :end_date, :price

        def initialize(start_date, end_date, price)
          @start_date = start_date
          @end_date = end_date
          @price = price
        end

        def include?(date)
          date.between?(start_date, end_date)
        end
      end

      attr_reader :accommodation_code, :user_code, :login_ga, :periods

      def initialize(accommodation_code, user_code, login_ga, periods)
        @accommodation_code = accommodation_code
        @user_code          = user_code
        @login_ga           = login_ga
        @periods            = periods
      end

      def min_price(length)
        actual_periods(length).map(&:price).min
      end

      # Roomorama property id for given accommodation
      def property_id
        @property_id ||= Avantio::PropertyId.from_avantio_ids(
          accommodation_code, user_code, login_ga
        ).property_id
      end

      # Returns periods which have price > 0 and have intersection with [today, today + length]
      def actual_periods(length)
        from = Date.today
        to = from + length
        periods.select do |p|
          p.price > 0 && from <= p.end_date && p.start_date <= to
        end
      end
    end
  end
end