module SAW
  module Entities
    class BeddingConfiguration
      attr_reader :number_of_single_beds, :number_of_double_beds

      def initialize(number_of_single_beds:, number_of_double_beds:)
        @number_of_single_beds = number_of_single_beds
        @number_of_double_beds = number_of_double_beds
      end

      def max_guests
        number_of_single_beds + number_of_double_beds * 2
      end
    end
  end
end
