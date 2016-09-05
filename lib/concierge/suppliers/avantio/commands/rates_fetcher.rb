module Avantio
  module Commands
    # +Avantio::Commands::RatesFetcher+
    #
    #
    class RatesFetcher
      CODE = 'rates'

      attr_reader :code_partner

      def initialize(code_partner)
        @code_partner = code_partner
      end

      def call
        rates_raw = fetcher.fetch(CODE)
        return rates_raw unless rates_raw.success?

        Result.new(build_rates(rates_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Rate.new
      end

      def build_rates(rates_raw)
        rates = rates_raw.xpath('/GetRatesListRS/AccommodationList/AccommodationRS')
        Array(rates).map do |rate|
          entity = mapper.build(rate)
          [entity.property_id, entity]
        end.to_h
      end
    end
  end
end