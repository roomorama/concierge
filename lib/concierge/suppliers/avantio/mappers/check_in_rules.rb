module Avantio
  module Mappers
    class CheckInRules

      RULES_SELECTOR = 'CheckInCheckOutInfo/CheckInRules/CheckInRule'

      attr_reader :common_services_raw, :special_services_raw

      def build(accommodation_raw)
        raw_rules = accommodation_raw.xpath(RULES_SELECTOR)

        Avantio::Entities::CheckInRules.new.tap do |rules|
          raw_rules.each do |raw_rule|
            rule = build_rule(raw_rule)
            rules.add_rule(rule)
          end
        end
      end

      private

      def build_rule(raw_rule)
        start_day   = raw_rule.at_xpath('Season/StartDay').text.to_i
        start_month = raw_rule.at_xpath('Season/StartMonth').text.to_i
        final_day   = raw_rule.at_xpath('Season/FinalDay').text.to_i
        final_month = raw_rule.at_xpath('Season/FinalMonth').text.to_i
        from        = raw_rule.at_xpath('Schedule/From').text
        to          = raw_rule.at_xpath('Schedule/To').text
        weekdays    = raw_rule.xpath('DaysOfApplication/*[text() = "true"]').map(&:name)

        Avantio::Entities::CheckInRules::Rule.new(start_day, start_month, final_day, final_month, from, to, weekdays)
      end
    end
  end
end
