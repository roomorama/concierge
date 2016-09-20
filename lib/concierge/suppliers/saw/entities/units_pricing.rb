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

      # Find unit rate by +unit_id+
      #
      # Arguments
      #   * +unit_id+
      #
      # Returns [SAW::Entities::UnitRate]
      def find_unit_rate(unit_id)
        units.detect { |u| u.id == unit_id }
      end

      # Determines whether unit with given +uni_id+ is present in units pricing
      # object or not.
      #
      # Arguments
      #   * +unit_id+
      #
      # Returns [Boolean] flag indicating the presence of rates for unit
      def has_rates_for_unit?(unit_id)
        !!find_unit(unit_id)
      end
    end
  end
end
