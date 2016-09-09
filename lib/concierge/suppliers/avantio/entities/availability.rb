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

      attr_reader :accommodation_code, :user_code, :login_ga, :occupational_rule_id, :periods

      def initialize(accommodation_code, user_code, login_ga, occupational_rule_id, periods)
        @accommodation_code   = accommodation_code
        @user_code            = user_code
        @login_ga             = login_ga
        @occupational_rule_id = occupational_rule_id
        @periods              = periods
      end

      # Returns periods which has intersection with [today, today + length]
      def actual_periods(length)
        from = Date.today
        to = from + length
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
    end
  end
end