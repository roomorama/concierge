module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::propertiescollection+
    #
    # This class is responsible for building a properties collection object
    class PropertiesCollection
      attr_reader :properties

      # Initialize +RentalsUnited::Mappers::PropertiesCollection+ mapper
      #
      # Arguments:
      #
      #   * +properties+ [Array] array with property collection hashes
      def initialize(properties)
        @properties = properties
      end

      def build_properties_collection
        entries = build_entries

        Entities::PropertiesCollection.new(entries)
      end

      private
      def build_entries
        properties.map do |hash|
          safe_hash = Concierge::SafeAccessHash.new(hash)
          {
            property_id: safe_hash.get("ID"),
            location_id: safe_hash.get("DetailedLocationID")
          }
        end
      end
    end
  end
end
