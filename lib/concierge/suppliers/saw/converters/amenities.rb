module SAW
  module Converters
    class Amenities
      class << self
        # Converts SAW facility services to Roomorama amenities
        #
        # @facility_services [Array<String>] array with SAW amenities
        # @return [Array<String>] array with uniq supported amenitites
        def convert(facility_services = [])
          roomorama_amenities = facility_services.map do |service_name|
            supported_amenities.fetch(service_name, nil)
          end.compact

          if roomorama_amenities.any?
            roomorama_amenities.uniq
          else
            []
          end
        end

        # Keeps only facility services which has no matches to Roomorama API
        # Facility services from array which are supported by API will not be
        # returned
        #
        # @facility_services [Array<String>] array with SAW amenities
        # @return [Array<String>] array with uniq unsupported amenitites
        def select_not_supported_amenities(facility_services = [])
          additional_amenities = []

          facility_services.each do |service_name|
            match = supported_amenities.fetch(service_name, nil)
            additional_amenities << service_name unless match
          end

          additional_amenities.uniq
        end

        # Returns a hash with mapping between SAW facility services and 
        # Roomorama API supported amenities
        #
        # @example Get supported amenities hash
        #   supported_amenities #=>
        #     {
        #       "Broadband": "internet",
        #       "Digital TV": "tv"
        #     }
        #
        # @return [Hash] hash with key-value matched pairs
        def supported_amenities
          @supported_amenities ||= load_supported_amenities
        end

        private
        def load_supported_amenities
          load_amenities["enabled-amenities"]
        end

        def load_amenities
          JSON.parse(File.read(amenities_file_path))
        end

        def amenities_file_path
          File.expand_path('../config/amenities.json', __FILE__)
        end
      end
    end
  end
end
