module Avantio
  module Commands
    # +Avantio::Commands::OccupationalRulesFetcher+
    #
    #
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