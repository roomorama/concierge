module SAW
  module Entities
    # +SAW::Entities::PropertyRate+
    #
    # This entity represents an object with available rates for units in
    # property.
    #
    # Attributes
    #
    # +id+         - id of the unit in SAW registry
    # +price+      - rate per night
    # +available+  - whether unit is available for booking
    # +max_guests+ - maximum number of guests for unit
    class UnitRate
      attr_reader :id, :price, :available, :max_guests

      def initialize(id:, price:, max_guests:, available:)
        @id         = id
        @price      = price
        @available  = available
        @max_guests = max_guests
      end

      def nightly_rate
        sprintf('%02.2f', price).to_f
      end

      def weekly_rate
        sprintf('%02.2f', price * 7).to_f
      end

      def monthly_rate
        sprintf('%02.2f', price * 30).to_f
      end
    end
  end
end
