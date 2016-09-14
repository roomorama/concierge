module Ciirus
  module Validators
    # +Ciirus::Validators::PropertyValidator+
    #
    # This class responsible for properties validation.
    # cases when property invalid:
    #
    #   * bad property type
    #   * invalid coordinates
    #   * property contains demo image
    #
    class PropertyValidator
      UNSUPPORTED_PROPERTY_TYPES = ['Office', 'Barn', 'Resort', 'Unspecified', 'Hotel']

      # An easy way for us to establish if a unit is likely to have demo images,
      # is if the getproperties response contains the following value for the respective property:
      # This is not 100% effective at identifying demo images, but this should get 95%
      DEMO_IMAGE_URL = 'http://images.ciirus.com/properties/37961/105836/images/ccpdemo1.jpg'

      attr_reader :property

      def initialize(property)
        @property = property
      end

      def valid?
        valid_property_type? && valid_coordinates? && !demo_image?
      end

      private

      def valid_property_type?
        ! UNSUPPORTED_PROPERTY_TYPES.include?(property.type)
      end

      def valid_coordinates?
        property.xco != 0 || property.yco != 0
      end

      def demo_image?
        property.main_image_url == DEMO_IMAGE_URL
      end
    end
  end
end
