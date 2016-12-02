module Concierge

  # +Concierge::PropertyDescription+
  #
  # If property does not have description this class helps to build
  # it from property attributes. If some of required attributes is missed empty string will be returned.
  #
  # Usage:
  #
  #  PropertyDescription.new(property).build # => String
  class PropertyDescription
    attr_reader :property

    def initialize(property)
      @property = property
    end

    def build
      result = ''
      if valid?
        result = "This is a charming #{property.type} in #{property.city}, which can accommodate "\
        "#{pluralize(property.max_guests, 'guest', 'guests')}. "

        rooms_part_start = if property.surface
                             "The #{property.surface} square metres apartment"
                           else
                             "It"
                           end

        result += "#{rooms_part_start} has #{pluralize(property.number_of_bedrooms, 'bedroom', 'bedrooms')} and "\
          "#{pluralize(property.number_of_bathrooms, 'bathroom', 'bathrooms')}."
      end

      result
    end

    private

    def valid?
      property.type &&
        property.city &&
        property.max_guests.to_i > 0 &&
        property.number_of_bedrooms.to_i > 0 &&
        property.number_of_bathrooms.to_i > 0
    end

    def pluralize(n, singular, plural=nil)
      if n == 1
        "1 #{singular}"
      elsif plural
        "#{n} #{plural}"
      else
        "#{n} #{singular}s"
      end
    end
  end
end