module SAW
  module Entities
    # +SAW::Entities::BeddingConfiguration+
    #
    # This entity is an object for representing the configuration of available
    # bed types for property (units)
    #
    # Attributes
    #
    # +number_of_single_beds+ - number of single beds in unit
    # +number_of_double_beds+ - number of double beds in unit
    class BeddingConfiguration
      attr_reader :number_of_single_beds, :number_of_double_beds

      def initialize(number_of_single_beds:, number_of_double_beds:)
        @number_of_single_beds = number_of_single_beds
        @number_of_double_beds = number_of_double_beds
      end

      # Calculate how much guests can stay in the unit by counting
      # available single and double beds
      #
      # Returns [Integer] number of guests
      def max_guests
        number_of_single_beds + number_of_double_beds * 2
      end
    end
  end
end
