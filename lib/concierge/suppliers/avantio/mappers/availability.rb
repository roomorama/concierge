module Avantio
  module Mappers
    class Availability

      def build(rate_raw)
        accommodation_code = fetch_accommodation_code(rate_raw)
        user_code = fetch_user_code(rate_raw)
        login_ga = fetch_login_ga(rate_raw)
        occupational_rule_id = fetch_occupational_rule_id(rate_raw)
        periods = fetch_periods(rate_raw)

        Avantio::Entities::Availability.new(
          accommodation_code, user_code, login_ga, occupational_rule_id, periods
        )
      end

      private

      def fetch_accommodation_code(rate_raw)
        rate_raw.at_xpath('AccommodationCode')&.text.to_s
      end

      def fetch_user_code(rate_raw)
        rate_raw.at_xpath('UserCode')&.text.to_s
      end

      def fetch_login_ga(rate_raw)
        rate_raw.at_xpath('LoginGA')&.text.to_s
      end

      def fetch_occupational_rule_id(rate_raw)
        rate_raw.at_xpath('OccupationalRuleId')&.text.to_s
      end

      def fetch_periods(rate_raw)
        periods = rate_raw.xpath('Availabilities/AvailabilityPeriod')
        Array(periods).map do |p|
          start_date = p.at_xpath('StartDate').text
          end_date = p.at_xpath('EndDate').text
          state = p.at_xpath('State').text
          Avantio::Entities::Availability::Period.new(
            Date.parse(start_date),
            Date.parse(end_date),
            state
          )
        end
      end
    end
  end
end
