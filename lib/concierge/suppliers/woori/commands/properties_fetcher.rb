module Woori
  module Commands
    # +Woori::Commands::PropertiesFetcher+
    #
    # This class is responsible for wrapping the logic related to fetching
    # properties for Woori import file.
    #
    # Usage
    #
    #   command = Woori::Commands::PropertiesFetcher.new(file)
    #   properties = command.load_all_properties
    class PropertiesFetcher
      include Concierge::JSON

      attr_reader :file

      # Initialize a new `Woori::Commands::PropertiesFetcher` object.
      #
      # Usage:
      #
      #   Woori::Commands::PropertiesFetcher.new(file)
      def initialize(file)
        @file = file
      end

      # Builds and returns +Roomorama::Property+ objects.
      #
      # There is additional filtering step which removes not active properties
      # from the result set.
      def load_all_properties
        raw_properties.map do |propery_hash|
          safe_hash = Concierge::SafeAccessHash.new(propery_hash)

          next if safe_hash.get("data.isActive") != 1

          mapper = Woori::Mappers::RoomoramaProperty.new(safe_hash)
          mapper.build_property
        end.compact
      end
      
      private

      # Method doesn't convert `Hash` object to `Concierge::SafeAccessHash`
      # because `propery_hash` is a big object and it doesn't make sense to
      # perform this convertion just for two key access operations.
      def raw_properties
        properties_data = properties_hash["data"]
        return [] unless properties_data

        items = properties_data["items"]
        return [] unless items

        items
      end

      def properties_result
        json_decode(file)
      end

      def properties_hash
        properties_result.value
      end
    end
  end
end
