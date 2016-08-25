module Ciirus
  module Validators
    # +Ciirus::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * bad property type
    #   * unknown country
    #
    class PropertyValidator
      SUPPORTED_PROPERTY_TYPES = ['Office', 'Barn', 'Resort', 'Unspecified', 'Hotel']
      attr_reader :property

      def initialize(property)
        @property = property
      end

      def valid?
        valid_property_type?
      end

      private

      def valid_property_type?
        ! SUPPORTED_PROPERTY_TYPES.include?(property.type)
      end
    end
  end
end
