module Avantio
  module Validators
    # +Avantio::Validators::PropertyValidator+
    #
    # This class responsible for property validation.
    # cases when description is invalid:
    #
    #   * type of property is not supported by Roomorama
    #   * bedrooms count is unknown
    #
    class PropertyValidator
      attr_reader :property

      # Garage/Parking, Hotel
      UNSUPPORTED_PROPERTY_TYPES = ['10', '3']

      # Property is an instance of +Avantio::Entities::Accommodation+
      def initialize(property)
        @property = property
      end

      def valid?
        error_message.empty?
      end

      def error_message
        errors = []
        errors << "Property of type Garage/Parking or Hotel is not supported." unless valid_property_type?
        errors << "Number of bedrooms not given." unless property.bedrooms
        errors.join("\n")
      end

      private

      def valid_property_type?
        !UNSUPPORTED_PROPERTY_TYPES.include?(property.master_kind_code)
      end
    end
  end
end
