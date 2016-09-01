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
        'House'                    => ['house', 'house'],
        'Beach house'              => ['house', 'beach_house'],
        'Lake house'               => ['house', 'lake_house'],
        'Mountain house'           => ['house', 'house'],
        'Country house / villa'    => ['house', 'villa'],
        'Cottage / chalet / cabin' => ['house', 'chalet'],
        'Bungalow'                 => ['house', 'bungalow'],
        'Town house'               => ['house', 'townhouse'],
        'Mobile home'              => ['room', 'cabin'],
        'Bed and breakfast'        => ['bnb', 'room'],
        'Share house'              => ['house', 'house'],
        'Apartment'                => ['apartment', 'apartment'],
        'Condo'                    => ['apartment', 'luxury_apartment'],
        'Penthouse'                => ['apartment', 'luxury_apartment'],
        'Camping'                  => ['room', 'cabin'],
        'Other'                    => ['room', nil],
        'Houseboat'                => ['house', 'house']
      }
    end

  end
end