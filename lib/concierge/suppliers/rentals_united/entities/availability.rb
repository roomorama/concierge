module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Availability+
    #
    # This entity represents an availability type object.
    class Availability
      attr_accessor :date, :available, :minimum_stay, :changeover

      def initialize(date:, available:, minimum_stay:, changeover:)
        @date = date
        @available = available
        @minimum_stay = minimum_stay
        @changeover = changeover
      end
    end
  end
end
