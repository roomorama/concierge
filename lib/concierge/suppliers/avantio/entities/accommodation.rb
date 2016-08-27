module Avantio
  module Entities
    class Accommodation
      def initialize(attrs)
        @accommodation_code =   attrs[:accommodation_code]
        @user_code =            attrs[:user_code]
        @login_ga =             attrs[:login_ga]
        @accommodation_name =   attrs[:accommodation_name]
        @master_kind_code =     attrs[:master_kind_code]
        @country_iso_code =     attrs[:country_iso_code]
        @city =                 attrs[:city]
        @lat =                  attrs[:lat]
        @lng =                  attrs[:lng]
        @currency =             attrs[:currency]
        @postal_code =          attrs[:postal_code]
        @people_capacity =      attrs[:people_capacity]
        @minimum_occupation =   attrs[:minimum_occupation]
        @bedrooms =             attrs[:bedrooms]
        @double_beds =          attrs[:double_beds]
        @individual_beds =      attrs[:individual_beds]
        @individual_sofa_beds = attrs[:individual_sofa_beds]
        @double_sofa_beds =     attrs[:double_sofa_beds]
        @berths =               attrs[:berths]
        @housing_area =         attrs[:housing_area]
        @area_unit =            attrs[:area_unit]
        #   add other data
      end
    end
  end
end