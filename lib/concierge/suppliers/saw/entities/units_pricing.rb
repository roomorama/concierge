module SAW
  module Entities
    # +SAW::Entities::UnitsPricing+
    #
    # This entity represents an object with available rates for property
    # units: entity includes +units+ array which has unit rates and the
    # currency used for the current property
    #
    # Attributes
    #
    # +property_id+ - property id
    # +currency+    - currency code
    # +units+       - array of +SAW::Entities::UnitRate+ objects
    class UnitsPricing
      attr_reader :property_id, :units, :currency

      def initialize(property_id:, units:, currency:)
        @property_id = property_id
        @units = units
        @currency = currency
      end
    end
  end
end
