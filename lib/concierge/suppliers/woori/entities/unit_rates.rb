module Woori
  module Entities
    # +Woori::Entities::UnitRates+
    #
    # This entity represents an object with rates for unit.
    #
    # Attributes
    #
    # +nightly_rate+ - rate per night
    # +weekly_rate+  - rate per week
    # +monthly_rate+ - rate per month
    class UnitRates
      attr_reader :nightly_rate, :weekly_rate, :monthly_rate

      def initialize(nightly_rate:, weekly_rate:, monthly_rate:)
        @nightly_rate = nightly_rate
        @weekly_rate  = weekly_rate
        @monthly_rate = monthly_rate
      end
    end
  end
end
