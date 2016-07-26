module Woori
  module Converters
    # +Woori::Converters::Amenities+
    #
    # This class is responsible for mapping amenitites between Woori and
    # Roomorama APIs.
    class Amenities
      attr_reader :facility_services

      # Initialize amenities converter
      #  
      # Arguments
      #   
      #   * +facility_services+ [Array<String>] array with Woori amenities
      def initialize(facility_services = [])
        @facility_services = Array(facility_services)
      end

      # Converts Woori facility services to Roomorama amenities
      #
      # Example
      #   
      #   Woori::Converters::Amenities.convert(
      #     ["air conditioner", "swimming pool"]
      #   )
      #   => ["airconditioning", "pool"]
      #
      # Returns +Array<String>+ array with uniq supported amenitites
      def convert
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
      # Example
      #
      #   Woori::Converters::Amenities.select_not_supported_amenities(
      #     ["internet", "foobar"]
      #   )
      #   => ["foobar"]
      #
      # Returns +Array<String>+ array with uniq unsupported amenitites
      def select_not_supported_amenities
        additional_amenities = []

        facility_services.each do |service_name|
          match = supported_amenities.fetch(service_name, nil)
          additional_amenities << service_name unless match
        end

        additional_amenities.uniq
      end


      # Returns a hash with mapping between Woori facility services and 
      # Roomorama API supported amenities
      #
      # Example
      #
      #   Woori::Converters::Amenities.supported_amenities
      #
      #   => {
      #     "Broadband": "internet",
      #     "Digital TV": "tv"
      #   }
      #
      # Returns +Hash+ hash with key-value matched pairs
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
