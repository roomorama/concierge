module Avantio
  module Mappers
    class OccupationalRule

      WEEKDAYS = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']

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
          min_nights = s.at_xpath('MinimumNights')&.text&.to_i

          checkin_weekdays = s.xpath('CheckInDays/WeekDay').map(&:text).select { |x| weekday?(x) }
          checkin_days = s.xpath('CheckInDays/MonthDay').map(&:text).select { |x| integer?(x) }

          checkout_weekdays = s.xpath('CheckOutDays/WeekDay').map(&:text).select { |x| weekday?(x) }
          checkout_days = s.xpath('CheckOutDays/MonthDay').map(&:text).select { |x| integer?(x) }
          Avantio::Entities::OccupationalRule::Season.new(
            Date.parse(start_date),
            Date.parse(end_date),
            min_nights,
            checkin_days,
            checkin_weekdays,
            checkout_days,
            checkout_weekdays
          )
        end
      end

      def integer?(str)
        str.to_i.to_s == str
      end

      def weekday?(str)
        WEEKDAYS.include?(str)
      end
    end
  end
end
