module Ciirus
  # +Ciirus::PropertyValidator+
  #
  # This class responsible for properties validation.
  # cases when property invalid:
  #
  #   * bad property type
  #
  class PropertyValidator
    attr_reader :property

    def initialize(property)
      @property = property
    end

    def valid?
      valid_property_type?
    end

    private

    def valid_property_type?
      # Roomorama doesn't import hotels
      !(['Unspecified', 'Hotel'].include?(property.type))
    end
  end
end
