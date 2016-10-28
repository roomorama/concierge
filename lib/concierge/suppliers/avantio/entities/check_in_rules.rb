module Avantio
  module Entities
    # Avantio provides check in rules. The class wrapping each rule ands allow to convert it to
    # the sting.
    class CheckInRules

      # The class represents one rule.
      #
      # Example of the rule:
      #
      # <CheckInRule>
      #   <Season>
      #     <StartDay>3</StartDay>
      #     <StartMonth>6</StartMonth>
      #     <FinalDay>30</FinalDay>
      #     <FinalMonth>9</FinalMonth>
      #   </Season>
      #   <Schedule>
      #     <From>17:00</From>
      #     <To>20:00</To>
      #   </Schedule>
      #   <DaysOfApplication>
      #     <Monday>true</Monday>
      #     <Tuesday>true</Tuesday>
      #     <Wednesday>true</Wednesday>
      #     <Thursday>true</Thursday>
      #     <Friday>true</Friday>
      #     <Saturday>false</Saturday>
      #     <Sunday>false</Sunday>
      #   </DaysOfApplication>
      # </CheckInRule>
      class Rule
        attr_reader :start_day, :start_month, :final_day, :final_month, :from, :to, :weekdays

        def initialize(start_day, start_month, final_day, final_month, from, to, weekdays)
          @start_day   = start_day
          @start_month = start_month
          @final_day   = final_day
          @final_month = final_month
          @from        = from
          @to          = to
          @weekdays    = weekdays
        end

        def season
          return '' if year_around_rule?

          from_month = Date::ABBR_MONTHNAMES[start_month]
          to_month = Date::ABBR_MONTHNAMES[final_month]
          "#{start_day} #{from_month} - #{final_day} #{to_month}"
        end

        def year_around_rule?
          start_day == 1 && start_month == 1 && final_day == 31 && final_month == 12
        end

        def anyweekday?
          weekdays.length == 7
        end

        def time
          if from == '00:00' && to == '00:00'
            'anytime'
          else
            "from #{from} to #{to}"
          end
        end
      end

      attr_reader :rules

      def initialize
        @rules = []
      end

      def add_rule(rule)
        @rules << rule
      end

      # Build string representation of rules.
      # For examples see specs.
      def to_s
        parts = []

        season_rules = @rules.group_by(&:season)

        season_rules.each do |season, rules|
          indent = ''
          unless season.empty?
            indent = '  '
            parts << "#{season}"
          end

          rule = rules[0]
          if rule.anyweekday?
            parts << "#{rule.time}"
          else
            weekdays_parts = []
            Date::DAYNAMES.each do |weekday|
              day_rule = rules.find { |rule| rule.weekdays.include?(weekday) }
              if day_rule
                weekdays_parts << "#{indent}#{weekday}: #{day_rule.time}"
              end
            end

            parts << weekdays_parts.join("\n")
          end
        end

        parts.join("\n")
      end
    end
  end
end