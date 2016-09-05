module Avantio
  module Entities
    class Rate
      # Count of days
      PERIOD_LENGTH = 365

      attr_reader :accommodation_code, :user_code, :login_ga, :periods

      def initialize(accommodation_code, user_code, login_ga, periods)
        @accommodation_code = accommodation_code
        @user_code          = user_code
        @login_ga           = login_ga
        @periods            = periods
      end

      def actual_periods
        from = Date.today
        to = from + PERIOD_LENGTH
        seasons.select do |s|
          s[:rate] > 0 &&
            from < s[:end_date] &&
            s[:start_date] <= to
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