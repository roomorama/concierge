module Avantio
  module Commands
    # +Avantio::Commands::AvailabilitiesFetcher+
    #
    # Avantio provides availabilities in zipped file available by URL.
    # This class fetches the file and parses the availabilities to the
    # hash: keys are property_id, values are instances of +Avantio::Entities::Availability+
    #
    # Usage
    #
    #   command = Avantio::Commands::AvailabilitiesFetcher.new(code_partner)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Hash
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the hash: keys are property_id,
    # values are instances of +Avantio::Entities::Availability+.
    class AvailabilitiesFetcher
      CODE = 'availabilities'

      attr_reader :code_partner

      def initialize(code_partner)
        @code_partner = code_partner
      end

      def call
        availabilities_raw = fetcher.fetch(CODE)
        return availabilities_raw unless availabilities_raw.success?

        Result.new(build_availabilities(availabilities_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Availability.new
      end

      def build_availabilities(availabilities_raw)
        availabilities = availabilities_raw.xpath('/GetAvailabilitiesRS/AccommodationList/AccommodationRS')
        Array(availabilities).map do |availability|
          entity = mapper.build(availability)
          [entity.property_id, entity]
        end.to_h
      end
    end
  end
end