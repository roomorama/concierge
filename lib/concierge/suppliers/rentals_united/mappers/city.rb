module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::City+
    #
    # This class is responsible for building a +RentalsUnited::Entities::City+
    # object from a hash which was fetched from the RentalsUnited API.
    class City
      attr_reader :city

      # Initialize +RentalsUnited::Mappers::City+
      #
      # Arguments:
      #
      #   * +city+ [Nori::StringWithAttributes] city object
      def initialize(city)
        @city = city
      end

      # Builds a city
      #
      # Returns [RentalsUnited::Entities::City]
      def build
        Entities::City.new(
          location_id: city.attributes["LocationID"],
          properties_count: city.to_i
        )
      end
    end
  end
end
