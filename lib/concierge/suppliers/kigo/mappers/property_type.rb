module Kigo::Mappers
  # +Kigo::Mappers::PropertyType+
  #
  # This class performs property type and subtype matched by provided id with reference data
  class PropertyType

    attr_reader :references

    def initialize(references)
      @references = references
    end

    def map(id)
      property_type = references.find { |item| item['PROP_TYPE_ID'] == id }
      type_mapping[property_type['PROP_TYPE_LABEL']] if property_type
    end

    private

    # Skipped property types (hostel, hotel, resort)
    def type_mapping
      {
        'House'                    => ['house', nil],
        'Beach house'              => ['house', nil],
        'Lake house'               => ['house', nil],
        'Mountain house'           => ['house', nil],
        'Country house / villa'    => ['house', 'villa'],
        'Cottage / chalet / cabin' => ['house', nil],
        'Bungalow'                 => ['house', 'bungalow'],
        'Town house'               => ['house', nil],
        'Mobile home'              => ['house', 'cabin'],
        'Bed and breakfast'        => ['bnb', nil],
        'Share house'              => ['room', nil],
        'Apartment'                => ['apartment', nil],
        'Condo'                    => ['apartment', 'condo'],
        'Penthouse'                => ['apartment', 'luxury_apartment'],
        'Camping'                  => ['house', 'cabin'],
        'Other'                    => ['room', nil],
        'Houseboat'                => ['house', nil]
      }
    end

  end
end
