module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Price+
    #
    # This entity represents a price object.
    class Price
      attr_accessor :total

      def initialize(total:, available:)
        @total     = total
        @available = available
      end

      def available?
        @available
      end
    end
  end
end
