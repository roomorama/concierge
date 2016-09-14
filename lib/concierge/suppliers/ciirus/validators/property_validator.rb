module Ciirus
  module Validators
    # +Ciirus::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * bad property type
    #   * invalid coordinates
    #
    class PropertyValidator
      UNSUPPORTED_PROPERTY_TYPES = ['Office', 'Barn', 'Resort', 'Unspecified', 'Hotel']
      attr_reader :property

      def initialize(property)
        @property = property
      end

      def valid?
        valid_property_type? && valid_coordinates?
      end

      private

      def valid_property_type?
        ! UNSUPPORTED_PROPERTY_TYPES.include?(property.type)
      end

      def valid_coordinates?
        property.xco != 0 || property.yco != 0
      end
    end
  end
end
