module RentalsUnited
  module Dictionaries
    # +RentalsUnited::Dictionaries::Amenities+
    #
    # This class is responsible for mapping amenitites between RU and
    # Roomorama APIs.
    class Amenities
      attr_reader :facility_service_ids

      SMOKING_ALLOWED_IDS = ["799", "802"]
      PETS_ALLOWED_IDS = ["595"]

      # Initialize amenities converter
      #
      # Arguments
      #
      #   * +acility_service_ids+ [Array<String>]
      def initialize(facility_service_ids)
        @facility_service_ids = Array(facility_service_ids)
      end

      # Converts RU facility services to Roomorama amenities
      #
      # Returns +Array<String>+ array with uniq supported amenitites
      def convert
        roomorama_amenities = facility_service_ids.map do |service_id|
          amenity = self.class.find(service_id)
          amenity["roomorama_name"] if amenity
        end

        roomorama_amenities.compact.uniq
      end

      def smoking_allowed?
        facility_service_ids.any? { |id| SMOKING_ALLOWED_IDS.include?(id) }
      end

      def pets_allowed?
        facility_service_ids.any? { |id| PETS_ALLOWED_IDS.include?(id) }
      end

      class << self
        # Looks up for supported amenity by id.
        # Returns nil if supported amenity was not found.
        #
        # Arguments
        #
        #   * +service_id+ [String] rentals united id of facility service
        #
        # Returns a +Hash+ with mapping if supported facility service is found
        # and +nil+ when there is no supported service with given id.
        def find(service_id)
          supported_amenities.find { |amenity| amenity["id"] == service_id }
        end

        # Returns a hash with mapping between Rentals United facility services
        # and Roomorama API supported amenities
        #
        # Returns an +Array+ with +Hash+ objects
        def supported_amenities
          @supported_amenities ||= load_amenities["enabled-amenities"]
        end

        def load_amenities
          JSON.parse(File.read(file_path))
        end

        def file_path
          Hanami.root.join(
            "lib/concierge/suppliers/rentals_united/dictionaries",
            "amenities.json"
          ).to_s
        end
      end
    end
  end
end
