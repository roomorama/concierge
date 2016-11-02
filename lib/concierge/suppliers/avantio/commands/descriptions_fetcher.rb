module Avantio
  module Commands
    # +Avantio::Commands::DescriptionsFetcher+
    #
    # Avantio provides accommodations' descriptions in zipped file available by URL.
    # This class fetches the file and parses the descriptions to the
    # hash: keys are property_id, values are instances of +Avantio::Entities::Description+
    #
    # Usage
    #
    #   command = Avantio::Commands::DescriptionsFetcher.new(code_partner)
    #   result = command.call
    #
    #   if result.success?
    #     result.value # Hash
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the hash: keys are property_id,
    # values are instances of +Avantio::Entities::Description+.
    class DescriptionsFetcher
      CODE = 'descriptions'

      attr_reader :code_partner

      def initialize(code_partner)
        @code_partner = code_partner
      end

      def call
        descriptions_raw = fetcher.fetch(CODE)
        return descriptions_raw unless descriptions_raw.success?

        Result.new(build_descriptions(descriptions_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(code_partner)
      end

      def mapper
        @mapper ||= Avantio::Mappers::Description.new
      end

      def build_descriptions(descriptions_raw)
        descriptions = descriptions_raw.xpath('/AccommodationList/AccommodationItem')
        Array(descriptions).map do |description|
          entity = mapper.build(description)
          [entity.property_id, entity]
        end.to_h
      end
    end
  end
end