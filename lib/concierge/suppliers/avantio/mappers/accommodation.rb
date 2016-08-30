module Avantio
  module Mappers
    class Accommodation

      SELECTORS = {
        accommodation_code:     'AccommodationCode',
        user_code:              'UserCode',
        login_ga:               'LoginGA',
        accommodation_name:     'AccommodationName',
        master_kind_code:       'MasterKind/MasterKindCode',
        country_iso_code:       'LocalizationData/Country/ISOCode',
        city:                   'LocalizationData/City/Name',
        lat:                    'LocalizationData/GoogleMaps/Latitude',
        lng:                    'LocalizationData/GoogleMaps/Longitude',
        district:               'LocalizationData/District/Name',
        postal_code:            'LocalizationData/District/PostalCode',
        street:                 'LocalizationData/Way',
        number:                 'LocalizationData/Number',
        block:                  'LocalizationData/Block',
        door:                   'LocalizationData/Door',
        floor:                  'LocalizationData/Floor',
        currency:               'Currency',
        people_capacity:        'Features/Distribution/PeopleCapacity',
        minimum_occupation:     'Features/Distribution/MinimumOccupation',
        bedrooms:               'Features/Distribution/Bedrooms',
        double_beds:            'Features/Distribution/DoubleBeds',
        individual_beds:        'Features/Distribution/IndividualBeds',
        individual_sofa_beds:   'Features/Distribution/IndividualSofaBed',
        double_sofa_beds:       'Features/Distribution/DoubleSofaBed',
        berths:                 'Features/Distribution/Berths',
        housing_area:           'Features/Distribution/AreaHousing/Area',
        area_unit:              'Features/Distribution/AreaHousing/AreaUnit',
        bathtub_bathrooms:      'Features/Distribution/BathroomWithBathtub',
        shower_bathrooms:       'Features/Distribution/BathroomWithShower',
        pool_type:              'Features/HouseCharacteristics/SwimmingPool/PoolType',
        tv:                     'Features/HouseCharacteristics/TV',
        fire_place:             'Features/HouseCharacteristics/FirePlace',
        garden:                 'Features/HouseCharacteristics/Garden',
        bbq:                    'Features/HouseCharacteristics/Barbacue',
        terrace:                'Features/HouseCharacteristics/Terrace',
        fenced_plot:            'Features/HouseCharacteristics/FencedPlot',
        elevator:               'Features/HouseCharacteristics/Elevator',
        dvd:                    'Features/HouseCharacteristics/DVD',
        balcony:                'Features/HouseCharacteristics/Balcony',
        gym:                    'Features/HouseCharacteristics/Gym',
        handicapped_facilities: 'Features/HouseCharacteristics/HandicappedFacilities',
        number_of_kitchens:     'Features/HouseCharacteristics/Kitchen/NumberOfKitchens'
      }

      def build(accommodation_raw)
        attrs = fetch_attrs(accommodation_raw)
        convert_attrs!(attrs)
        Avantio::Entities::Accommodation.new(attrs)
      end

      private

      def fetch_attrs(accommodation_raw)
        SELECTORS.map do |attr, selector|
          [attr, accommodation_raw.at_xpath(selector)&.text.to_s]
        end.to_h
      end

      def convert_attrs!(attrs)
        to_i = [:people_capacity, :minimum_occupation, :bedrooms, :double_beds,
                :individual_beds, :individual_sofa_beds, :double_sofa_beds, :berths,
                :housing_area, :number_of_kitchens, :bathtub_bathrooms,
                :shower_bathrooms, :floor]
        to_i.each do |attr|
          value = attrs[attr]
          attrs[attr] = (value.to_i unless value.empty?)
        end

        to_bool = [:tv, :fire_place, :garden, :bbq, :terrace, :fenced_plot,
                   :elevator, :dvd, :balcony, :gym]
        to_bool.each do |attr|
          value = attrs[attr]
          attrs[attr] = (value == 'true' unless value.empty?)
        end
      end
    end
  end
end
