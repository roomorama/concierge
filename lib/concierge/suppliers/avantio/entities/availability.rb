module Avantio
  module Entities
    class Availability
      class Period
        attr_reader :start_date, :end_date

        def initialize(start_date, end_date, state)
          @start_date = start_date
          @end_date = end_date
          @state = state
        end

        def available?
          state == 'AVAILABLE'
        end

        private

        attr_reader :state
      end
      # Count of days
      PERIOD_LENGTH = 365

      attr_reader :accommodation_code, :user_code, :login_ga, :periods

      def initialize(accommodation_code, user_code, login_ga, periods_array)
        @accommodation_code = accommodation_code
        @user_code          = user_code
        @login_ga           = login_ga
        @periods            = build_periods(periods_array)
      end

      def actual_periods
        from = Date.today
        to = from + PERIOD_LENGTH
        periods.select do |p|
          from < p.end_date && p.start_date <= to
        end
      end

      # Roomorama property id for given accommodation
      def property_id
        @property_id ||= Avantio::PropertyId.from_avantio_ids(
          accommodation_code, user_code, login_ga
        ).property_id
      end

      private

      def build_periods(periods_array)
        periods_array.map { |p| Period.new(p[:start_date], p[:end_date], p[:state]) }
      end
    end
  end
end