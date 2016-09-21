module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Location+
    #
    # This class is responsible for building a location object.
    class Location
      attr_reader :location_id, :raw_locations_database

      # Rentals United mapping of location ids and location types.
      # Worldwide and Continent type locations are not mapped.
      LOCATION_TYPES = {
        2 => :country,
        3 => :region,
        4 => :city,
        5 => :neighborhood
      }

      # Initialize +RentalsUnited::Mappers::Location+ mapper
      #
      # Arguments:
      #
      #   * +location_id+ [String] id of location
      #   * +raw_locations_database+ [Array<Hash>] database of locations data
      def initialize(location_id, raw_locations_database)
        @location_id = location_id
        @raw_locations_database = raw_locations_database
      end

      # Iterate over location hierarchy by location type id attribute.
      #
      # Each level of hierarchy provide location data: region, city, country
      # names.
      #
      # Iteration starts from the level of the current type of given location
      # and ends when hits "Country" type.
      def build_location
        location = Entities::Location.new(location_id)

        current_level = find_location_data(location_id)
        return nil unless current_level

        current_level_type = current_level[:type]

        location_hash = {}
        update_location_hash(location_hash, current_level)

        while(LOCATION_TYPES.keys.include?(current_level_type)) do
          parent_location_id = current_level[:parent_id]

          current_level = find_location_data(parent_location_id)
          return nil unless current_level

          current_level_type = current_level[:type]

          update_location_hash(location_hash, current_level)
        end

        location.load(location_hash)
      end

      private
      def find_location_data(id)
        raw_locations_database.find do |location|
          location[:id] == id
        end
      end

      def update_location_hash(location_hash, current_level)
        key = LOCATION_TYPES[current_level[:type]]
        value = current_level[:name]
        location_hash[key] = value
      end
    end
  end
end
