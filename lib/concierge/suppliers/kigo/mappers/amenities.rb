module Kigo::Mappers
  # +Kigo::Mappers::Amenity+ represents amenity structure
  Amenity = Struct.new(:id, :name, :category_id)
  #
  # +Kigo::Mappers::Amenities+
  #
  # Represents Kigo property payload to Roomorama format
  class Amenities
    KITCHEN_CATEGORY_ID = 6

    attr_reader :amenities

    def initialize(amenities)
      @amenities = amenities.map do |amenity|
        Amenity.new(amenity['AMENITY_ID'],
                    amenity['AMENITY_LABEL'],
                    amenity['AMENITY_CATEGORY_ID'])
      end
    end

    # Perform amenities list by their ID
    # Expects an Array of ids
    def map(ids)
      scope         = amenities.select { |amenity| ids.include?(amenity.id) }
      amenity_names = scope.map(&:name)
      result        = amenities_map.values_at(*amenity_names)
      result << 'kitchen' if has_kitchen_category?(scope)
      result << 'bed_linen_and_towels' if bed_linen_and_towels_provided?(amenity_names)

      result.compact.uniq
    end


    private

    def amenities_map
      {
        'Elevator'                          => 'elevator',
        'Concierge'                         => 'doorman',
        'Parking - garage'                  => 'parking',
        'Parking - private'                 => 'parking',
        'Parking - on-street'               => 'parking',
        'Parking - trailer/RV/Boat parking' => 'parking',
        'Wheelchair'                        => 'wheelchairaccess',
        'Washing machine'                   => 'laundry',
        'Dryer'                             => 'laundry',
        'Washer/Dryer'                      => 'laundry',
        'Cable/Satellite TV'                => 'cabletv',
        'TV'                                => 'tv',
        'High-speed Internet'               => 'internet',
        'Wifi'                              => 'wifi',
        'Air-conditioning'                  => 'airconditioning',
        'Balcony'                           => 'balcony',
        'Patio/deck/Terrace'                => 'outdoor_space',
        'Roofed Patio/deck/Terrace'         => 'outdoor_space',
        'Shared garden'                     => 'outdoor_space',
        'Private Garden'                    => 'outdoor_space',
        'Pool - private'                    => 'pool',
        'Pool - shared'                     => 'pool'
      }
    end

    def has_kitchen_category?(scope)
      scope.any? { |amenity| amenity.category_id == KITCHEN_CATEGORY_ID }
    end

    def bed_linen_and_towels_provided?(amenity_names)
      ['Bed linen provided', 'Towels provided'].all? { |name| amenity_names.include?(name) }
    end

  end
end