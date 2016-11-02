module Avantio
  module Commands
    # +Avantio::Commands::RatesFetcher+
    #
    # Avantio provides rates in zipped file available by URL.
    # This class fetches the file and parses the rates to the
    # hash: keys are property_id, values are instances of +Avantio::Entities::Rate+
    #
    # Usage
    #
    #   command = Avantio::Commands::RatesFetcher.new(code_partner)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Hash
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the hash: keys are property_id,
    # values are instances of +Avantio::Entities::Rate+.
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