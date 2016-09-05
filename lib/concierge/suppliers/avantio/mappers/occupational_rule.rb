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
          min_nights = s.at_xpath('MinimumNightsOnline')&.text.to_i
          {
            start_date: Date.parse(start_date),
            end_date:   Date.parse(end_date),
            min_nights: min_nights
          }
        end
      end
    end
  end
end
