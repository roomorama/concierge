module Avantio
  module Entities
    class Accommodation

      ATTRIBUTES = [
        :accommodation_code, :user_code, :login_ga, :accommodation_name, :master_kind_code, :country_iso_code,
        :city, :lat, :lng, :district, :postal_code, :street, :number, :block, :door, :floor, :currency,
        :people_capacity, :minimum_occupation, :bedrooms, :double_beds, :individual_beds, :individual_sofa_beds,
        :double_sofa_beds, :housing_area, :area_unit, :bathtub_bathrooms, :shower_bathrooms, :pool_type, :tv,
        :fire_place, :garden, :bbq, :terrace, :fenced_plot, :elevator, :dvd, :balcony, :gym,
        :handicapped_facilities, :number_of_kitchens, :washing_machine, :pets_allowed, :security_deposit_amount,
        :sercurity_deposit_type, :serucirty_deposit_currency_code, :services_cleaning, :services_cleaning_rate,
        :services_cleaning_required, :bed_linen, :towel, :parking, :airconditioning, :internet
      ]

      attr_reader *ATTRIBUTES

      def initialize(attrs)
        @accommodation_code              = attrs[:accommodation_code]
        @user_code                       = attrs[:user_code]
        @login_ga                        = attrs[:login_ga]
        @accommodation_name              = attrs[:accommodation_name]
        @master_kind_code                = attrs[:master_kind_code]
        @country_iso_code                = attrs[:country_iso_code]
        @city                            = attrs[:city]
        @lat                             = attrs[:lat]
        @lng                             = attrs[:lng]
        @district                        = attrs[:district]
        @postal_code                     = attrs[:postal_code]
        @street                          = attrs[:street]
        @number                          = attrs[:number]
        @block                           = attrs[:block]
        @door                            = attrs[:door]
        @floor                           = attrs[:floor]
        @currency                        = attrs[:currency]
        @people_capacity                 = attrs[:people_capacity]
        @minimum_occupation              = attrs[:minimum_occupation]
        @bedrooms                        = attrs[:bedrooms]
        @double_beds                     = attrs[:double_beds]
        @individual_beds                 = attrs[:individual_beds]
        @individual_sofa_beds            = attrs[:individual_sofa_beds]
        @double_sofa_beds                = attrs[:double_sofa_beds]
        @housing_area                    = attrs[:housing_area]
        @area_unit                       = attrs[:area_unit]
        @bathtub_bathrooms               = attrs[:bathtub_bathrooms]
        @shower_bathrooms                = attrs[:shower_bathrooms]
        @pool_type                       = attrs[:pool_type]
        @tv                              = attrs[:tv]
        @fire_place                      = attrs[:fire_place]
        @garden                          = attrs[:garden]
        @bbq                             = attrs[:bbq]
        @terrace                         = attrs[:terrace]
        @fenced_plot                     = attrs[:fenced_plot]
        @elevator                        = attrs[:elevator]
        @dvd                             = attrs[:dvd]
        @balcony                         = attrs[:balcony]
        @gym                             = attrs[:gym]
        @handicapped_facilities          = attrs[:handicapped_facilities] # need to be parsed
        @number_of_kitchens              = attrs[:number_of_kitchens]
        @washing_machine                 = attrs[:washing_machine]
        @pets_allowed                    = attrs[:pets_allowed]
        @security_deposit_amount         = attrs[:security_deposit_amount]
        @security_deposit_type           = attrs[:sercurity_deposit_type]
        @security_deposit_currency_code  = attrs[:serucirty_deposit_currency_code]
        @services_cleaning               = attrs[:services_cleaning]
        @services_cleaning_rate          = attrs[:services_cleaning_rate]
        @services_cleaning_required      = attrs[:services_cleaning_required]
        @bed_linen                       = attrs[:bed_linen]
        @towels                          = attrs[:towel]
        @parking                         = attrs[:parking]
        @airconditioning                 = attrs[:airconditioning]
        @internet                        = attrs[:internet]
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