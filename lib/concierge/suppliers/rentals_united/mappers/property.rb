module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Property+
    #
    # This class is responsible for building a
    # +RentalsUnited::Entities::Property+ object from a hash which was fetched
    # from the RentalsUnited API.
    class Property
      attr_reader :property_hash

      # Initialize +RentalsUnited::Mappers::Property+
      #
      # Arguments:
      #
      #   * +property_hash+ [Concierge::SafeAccessHash] property hash object
      def initialize(property_hash)
        @property_hash = property_hash
      end

      # Builds a property_hash
      #
      # Returns [RentalsUnited::Entities::Property]
      def build_property
        property = Roomorama::Property.new(property_hash.get("ID"))
        property.title = property_hash.get("Name")
        property
      end
    end
  end
end
