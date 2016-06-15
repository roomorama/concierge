module SAW
  module Entities
    class UnitRate
      attr_reader :id, :price

      def initialize(id:, price:)
        @id    = id
        @price = price
      end
    end
  end
end
