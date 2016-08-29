module Avantio
  module Entities
    class Accommodation

      PROPERTY_ID_SEPARATOR = '|'

      ATTRIBUTES = [
        :accommodation_code, :user_code, :login_ga, :accommodation_name, :master_kind_code,
        :country_iso_code, :city, :lat, :lng, :currency, :postal_code, :people_capacity,
        :minimum_occupation, :bedrooms, :double_beds, :individual_beds, :individual_sofa_beds,
        :double_sofa_beds, :berths, :housing_area, :area_unit, :pool_type, :tv, :garden,
        :bbq, :terrace, :fenced_plot, :elevator, :dvd, :balcony, :gym,
        :handicapped_facilities, :number_of_kitchens
      ]

      attr_reader *ATTRIBUTES

      def initialize(attrs)
        @accommodation_code     = attrs[:accommodation_code]
        @user_code              = attrs[:user_code]
        @login_ga               = attrs[:login_ga]
        @accommodation_name     = attrs[:accommodation_name]
        @master_kind_code       = attrs[:master_kind_code]
        @country_iso_code       = attrs[:country_iso_code]
        @city                   = attrs[:city]
        @lat                    = attrs[:lat]
        @lng                    = attrs[:lng]
        @street                 = attrs[:street]
        @number                 = attrs[:number]
        @block                  = attrs[:block]
        @door                   = attrs[:door]
        @currency               = attrs[:currency]
        @district               = attrs[:district]
        @postal_code            = attrs[:postal_code]
        @people_capacity        = attrs[:people_capacity]
        @minimum_occupation     = attrs[:minimum_occupation]
        @bedrooms               = attrs[:bedrooms]
        @double_beds            = attrs[:double_beds]
        @individual_beds        = attrs[:individual_beds]
        @individual_sofa_beds   = attrs[:individual_sofa_beds]
        @double_sofa_beds       = attrs[:double_sofa_beds]
        @berths                 = attrs[:berths]
        @housing_area           = attrs[:housing_area]
        @area_unit              = attrs[:area_unit]
        @pool_type              = attrs[:pool_type]
        @tv                     = attrs[:tv]
        @fire_place             = attrs[:fire_place]
        @garden                 = attrs[:garden]
        @bbq                    = attrs[:bbq]
        @terrace                = attrs[:terrace]
        @fenced_plot            = attrs[:fenced_plot]
        @elevator               = attrs[:elevator]
        @dvd                    = attrs[:dvd]
        @balcony                = attrs[:balcony]
        @gym                    = attrs[:gym]
        @handicapped_facilities = attrs[:handicapped_facilities] # need to be parsed
        @number_of_kitchens     = attrs[:number_of_kitchens]
      end

      # Roomorama property id for given accommodation
      def property_id
        Avantio::PropertyId.from_avantio_ids(
          accommodation_code, user_code, login_ga
        ).property_id
      end
    end
  end
end