module Kigo::Mappers
  # +Kigo::Mappers::PricingSetup+ is responsible for setting property base price
  #
  # It takes two prices payload from two different API calls.
  # See more details for each params:
  #   - base_rate:       +readProperty2+
  #   - periodical_rate: +readPropertyPricingSetup+
  #
  # the all prices going to be calculated from +nightly_rate+
  # Currently we check the nightly rate from base_rate, and fallback
  # to the minimum of periodical_rate
  class PricingSetup

    attr_reader :base_rate, :periodical_rate

    def initialize(base_rate, periodical_rate)
      @base_rate       = base_rate
      @periodical_rate = periodical_rate
    end

    def valid?
      nightly_rate.to_f > 0
    end

    def min_stay_valid?
      periodical_rate.get('MIN_STAY.MIN_STAY_RULES').is_a? Array
    end

    def nightly_rate
      @nightly_rate ||= base_nightly_rate || minimum_periodical_nightly_rate
    end

    def weekly_rate
      nightly_rate * 7
    end

    def monthly_rate
      nightly_rate * 30
    end

    def currency
      periodical_rate['CURRENCY']
    end

    def minimum_stay
      rules = periodical_rate.get('MIN_STAY.MIN_STAY_RULES')
      rules.collect do |rule|
        before_to = rule['DATE_TO'].nil? || DateTime.parse(rule['DATE_TO']) < DateTime.now
        after_from = rule['DATE_FROM'].nil? || DateTime.parse(rule['DATE_FROM']) > DateTime.now
        if before_to && after_from
          rule['MIN_STAY_VALUE']
        end
      end.first.to_i
    end

    private

    def base_nightly_rate
      return base_rate['PROP_RATE_NIGHTLY_FROM'].to_f if base_rate['PROP_RATE_NIGHTLY_FROM']
      return base_rate['PROP_RATE_WEEKLY_FROM'].to_f / 7 if base_rate['PROP_RATE_WEEKLY_FROM']
      return base_rate['PROP_RATE_MONTHLY_FROM'].to_f / 30 if base_rate['PROP_RATE_MONTHLY_FROM']
    end

    def minimum_periodical_nightly_rate
      periods = periodical_rate.get('RENT.PERIODS')
      Array(periods).map do |period|
        if period['WEEKLY']
          period['WEEKLY_AMOUNTS'].map { |d| d['AMOUNT'].to_f / 7 }
        else
          period['NIGHTLY_AMOUNTS'].map { |d| d['AMOUNT'].to_f }
        end
      end.flatten.min
    end

  end

end
