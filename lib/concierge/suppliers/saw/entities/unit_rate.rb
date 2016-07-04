module SAW
  module Entities
    # +SAW::Entities::PropertyRate+
    #
    # This entity represents an object with available rate for unit.
    # Rate is given per night.
    #
    # Attributes
    #
    # +id+    - id of the unit in SAW registry
    # +price+ - rate per night
    class UnitRate
      attr_reader :id, :price

      def initialize(id:, price:)
        @id    = id
        @price = price
      end
    end
  end
end
