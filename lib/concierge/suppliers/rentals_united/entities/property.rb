module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Property+
    #
    # This entity represents a property object.
    class Property
      attr_accessor :id, :title, :description, :lat, :lng, :address,
                    :postal_code, :check_in_time, :check_out_time, :max_guests,
                    :surface, :bedroom_type_id, :property_type_id, :floor,
                    :images, :amenities, :owner_id, :security_deposit_type,
                    :security_deposit_amount, :check_in_instructions,
                    :number_of_bathrooms

      attr_writer :active, :archived

      def initialize(id:, title:, description:, lat:, lng:, address:,
                     postal_code:, check_in_time:, check_out_time:, 
                     max_guests:, surface:, bedroom_type_id:, property_type_id:,
                     floor:, images:, amenities:, active:, archived:, owner_id:,
                     security_deposit_type:, security_deposit_amount:,
                     check_in_instructions:, number_of_bathrooms:)
        @id                      = id
        @title                   = title
        @description             = description
        @lat                     = lat
        @lng                     = lng
        @address                 = address
        @postal_code             = postal_code
        @check_in_time           = check_in_time
        @check_out_time          = check_out_time
        @check_in_instructions   = check_in_instructions
        @max_guests              = max_guests
        @surface                 = surface
        @bedroom_type_id         = bedroom_type_id
        @property_type_id        = property_type_id
        @owner_id                = owner_id
        @security_deposit_type   = security_deposit_type
        @security_deposit_amount = security_deposit_amount
        @floor                   = floor
        @active                  = active
        @archived                = archived
        @images                  = images
        @amenities               = amenities
        @number_of_bathrooms     = number_of_bathrooms
      end

      def active?
        @active
      end

      def archived?
        @archived
      end
    end
  end
end
