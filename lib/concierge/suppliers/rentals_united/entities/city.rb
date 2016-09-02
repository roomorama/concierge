module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::City+
    #
    # This entity represents a city object
    #
    # Attributes
    #
    # +location_id+      - city location id
    # +properties_count+ - number of properties in city
    class City
      attr_reader :location_id, :properties_count

      def initialize(location_id:, properties_count:)
        @location_id = location_id
        @properties_count = properties_count
      end
    end
  end
end
