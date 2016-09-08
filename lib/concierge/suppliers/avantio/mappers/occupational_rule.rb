module Avantio
  module Mappers
    class OccupationalRule

      def build(rule_raw)
        id = fetch_id(rule_raw)
        seasons = fetch_seasons(rule_raw)

        Avantio::Entities::OccupationalRule.new(id, seasons)
      end

      private

      def fetch_id(rule_raw)
        rule_raw.at_xpath('Id')&.text.to_s
      end

      def fetch_seasons(rule_raw)
        seasons = rule_raw.xpath('Season')
        Array(seasons).map do |s|
          start_date = s.at_xpath('StartDate').text
          end_date = s.at_xpath('EndDate').text
          # nils if they are not presented
          min_nights_online = s.at_xpath('MinimumNightsOnline')&.text&.to_i
          min_nights = s.at_xpath('MinimumNights')&.text&.to_i

          checkin_weekdays = s.xpath('CheckInDays/WeekDay').map(&:text)
          checkin_days = s.xpath('CheckInDays/MonthDay').map(&:text)

          checkout_weekdays = s.xpath('CheckOutDays/WeekDay').map(&:text)
          checkout_days = s.xpath('CheckOutDays/MonthDay').map(&:text)

          Avantio::Entities::OccupationalRule::Season.new(
            Date.parse(start_date),
            Date.parse(end_date),
            min_nights,
            min_nights_online,
            checkin_days,
            checkin_weekdays,
            checkout_days,
            checkout_weekdays
          )
        end
      end
    end
  end
end
