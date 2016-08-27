module Avantio
  module Mappers
    class Accommodation

      SELECTORS = {
        accommodation_code: 'AccommodationCode',
        user_code: 'UserCode',
        login_ga: 'LoginGA',
        accommodation_name: 'AccommodationName',
        master_kind_code: 'MasterKind/MasterKindCode',
        country_iso_code: 'LocalizationData/Country/ISOCode',
        city: 'LocalizationData/City/Name',
        lat: 'LocalizationData/GoogleMaps/Latitude',
        lng: 'LocalizationData/GoogleMaps/Longitude',
        currency: 'Currency',
        postal_code: 'LocalizationData/District/PostalCode',
        people_capacity: 'Features/Distribution/PeopleCapacity',
        minimum_occupation: 'Features/Distribution/MinimumOccupation',
        bedrooms: 'Features/Distribution/Bedrooms',
        double_beds: 'Features/Distribution/DoubleBeds',
        individual_beds: 'Features/Distribution/IndividualBeds',
        individual_sofa_beds: 'Features/Distribution/IndividualSofaBed',
        double_sofa_beds: 'Features/Distribution/DoubleSofaBed',
        berths: 'Features/Distribution/Berths',
        housing_area: 'Features/Distribution/AreaHousing/Area',
        area_unit: 'Features/Distribution/AreaHousing/AreaUnit',
      }

      def build(accommodation_raw)
        require 'byebug'; byebug
        attrs = SELECTORS.map do |attr, selector|
          [attr, accommodation_raw.xpath(selector).text]
        end.to_h

        Avantio::Entities::Accommodation.new(attrs)
      end
    end
  end
end