module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Price+
    #
    # This class is responsible for building a +Entities::Price+ object
    class Price
      attr_reader :price

      # Initialize Price mapper
      #
      # Arguments:
      #
      #   * +price+ [String] price
      def initialize(price)
        @price = price.to_s
      end

      # Builds price
      #
      # Returns [Entities::Price]
      def build_price
        Entities::Price.new(
          total:     price.to_f,
          available: price.empty? ? false : true
        )
      end
    end
  end
end
