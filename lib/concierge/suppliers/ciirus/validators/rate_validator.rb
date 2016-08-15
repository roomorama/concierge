module Ciirus
  module Validators
    # +Ciirus::Validators::RateValidator+
    #
    # This class responsible for property rate validation.
    # cases when rate invalid:
    #
    #   * daily price is 0
    #   * rate is outdate
    #
    # One of args is today date. It made to save consistency of more then one rate validation process.
    # Example:
    #
    #   today = Date.today
    #
    #   rates.select do |rate|
    #     validator = RateValidator.new(rate, today)
    #     validator.valid?
    #   end
    #
    class RateValidator
      attr_reader :rate, :today

      def initialize(rate, today)
        @rate = rate
        @today = today
      end

      def valid?
        positive_daily_rate? && actual?
      end

      private

      def positive_daily_rate?
        rate.daily_rate > 0
      end

      def actual?
        end_period_sync = today + Ciirus::Mappers::RoomoramaCalendar::PERIOD_SYNC
        rate.to_date > today && rate.from_date <= end_period_sync
      end
    end
  end
end
