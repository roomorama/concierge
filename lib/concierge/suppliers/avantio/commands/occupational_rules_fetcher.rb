module Avantio
  module Commands
    # +Avantio::Commands::OccupationalRulesFetcher+
    #
    # Avantio provides occupational rules in zipped file available by URL.
    # The file contains a set of occupational rules with ids. Each Avantio
    # accommodation has occupationalRuleId.
    #
    # This class fetches the file and parses the occupational rules to the
    # hash: keys are rule_id, values are instances of +Avantio::Entities::OccupationalRule+
    #
    # Usage
    #
    #   command = Avantio::Commands::OccupationalRulesFetcher.new(code_partner)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Hash
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the hash: keys are rule_id,
    # values are instances of +Avantio::Entities::OccupationalRule+.
    class OccupationalRulesFetcher
      CODE = 'occupationalrules'

      attr_reader :code_partner

      def initialize(code_partner)
        @code_partner = code_partner
      end

      def call
        rules_raw = fetcher.fetch(CODE)
        return rules_raw unless rules_raw.success?

        Result.new(build_rules(rules_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::OccupationalRule.new
      end

      def build_rules(rules_raw)
        rules = rules_raw.xpath('/OccupationalRuleList/OccupationalRule')
        Array(rules).map do |rule|
          entity = mapper.build(rule)
          [entity.id, entity]
        end.to_h
      end
    end
  end
end