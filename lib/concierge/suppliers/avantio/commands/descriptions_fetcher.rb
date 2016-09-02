module Avantio
  module Commands
    # +Avantio::Commands::DescriptionsFetcher+
    #
    #
    class DescriptionsFetcher
      CODE = 'descriptions'

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call
        descriptions_raw = fetcher.fetch(CODE)
        return descriptions_raw unless descriptions_raw.success?

        Result.new(build_descriptions(descriptions_raw.value))
      end

      private

      def fetcher
        @fetcher ||= Avantio::Fetcher.new(credentials.code_partner)
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