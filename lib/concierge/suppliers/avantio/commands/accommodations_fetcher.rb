module Avantio
  module Commands
    # +Avantio::Commands::AccommodationsFetcher+
    #
    # Avantio provides accommodations' information in file available by URL.
    # This class fetches the file and parses the accommodations to the
    # array of +Avantio::Entities::Accommodation+
    #
    # Usage
    #
    #   command = Avantio::Commands::AccommodationsFetcher.new(code_partner)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Array of Accommodation instance
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the array of +Avantio::Entities::Accommodation+.
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