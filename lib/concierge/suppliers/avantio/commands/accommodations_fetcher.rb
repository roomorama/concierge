module Avantio
  module Commands
    # +Avantio::Commands::AccommodationsFetcher+
    #
    #
    class AccommodationsFetcher
      CODE = 'accommodations'

      attr_reader :code_partner

      def initialize(code_partner)
        @code_partner = code_partner
      end

      def call
        accommodations_raw = fetcher.fetch(CODE)
        return accommodations_raw unless accommodations_raw.success?

        Result.new(build_accommodations(accommodations_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Accommodation.new
      end

      def build_accommodations(accommodations_raw)
        accommodations = accommodations_raw.xpath('/AccommodationList/AccommodationData')
        Array(accommodations).map { |accommodation| mapper.build(accommodation) }
      end
    end
  end
end