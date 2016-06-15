module SAW
  module Entities
    class PropertyRate
      attr_reader :units, :currency

      def initialize(units:, currency:)
        @units = units
        @currency = currency
      end

      def find_unit(id)
        units.detect { |u| u.id == id }
      end
    end
  end
end
