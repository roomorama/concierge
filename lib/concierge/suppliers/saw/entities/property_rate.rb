module SAW
  module Entities
    # +SAW::Entities::PropertyRate+
    #
    # This entity represents an object with available rates for property
    # units: entity includes +units+ array which has unit rates and the
    # currency used for the current property
    #
    # Attributes
    #
    # +units+   - array of SAW::Entities::UnitRate objects
    # +current+ - currency code
    class PropertyRate
      attr_reader :units, :currency

      def initialize(units:, currency:)
        @units = units
        @currency = currency
      end

      # Find unit by +id+
      #
      # Arguments
      #   * +id+
      #
      # Returns [SAW::Entities::UnitRate]
      def find_unit(id)
        units.detect { |u| u.id == id }
      end
    end
  end
end
