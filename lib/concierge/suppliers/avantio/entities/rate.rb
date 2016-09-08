module Avantio
  module Entities
    class Rate
      Period = Struct.new(:start_date, :end_date, :price)

      attr_reader :accommodation_code, :user_code, :login_ga, :periods

      def initialize(accommodation_code, user_code, login_ga, periods_array)
        @accommodation_code = accommodation_code
        @user_code          = user_code
        @login_ga           = login_ga
        @periods            = build_periods(periods_array)
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
          p.price > 0 && from < p.end_date && p.start_date <= to
        end
      end

      private

      def build_periods(periods_array)
        periods_array.map { |p| Period.new(p[:start_date], p[:end_date], p[:rate]) }
      end
    end
  end
end