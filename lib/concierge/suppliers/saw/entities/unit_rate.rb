module SAW
  module Entities
    # +SAW::Entities::PropertyRate+
    #
    # This entity represents an object with available rate for unit.
    # Rate is given per night.
    #
    # Attributes
    #
    # +id+        - id of the unit in SAW registry
    # +price+     - rate per night
    # +available+ - whether unit is available for booking
    class UnitRate
      attr_reader :id, :price, :available

      def initialize(id:, price:, available:)
        @id        = id
        @price     = price
        @available = available
      end
    end
  end
end
