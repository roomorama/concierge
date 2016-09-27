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
                    :security_deposit_amount

      attr_writer :active, :archived

      def initialize(id:, title:, description:, lat:, lng:, address:,
                     postal_code:, check_in_time:, check_out_time:, 
                     max_guests:, surface:, bedroom_type_id:, property_type_id:,
                     floor:, images:, amenities:, active:, archived:, owner_id:,
                     security_deposit_type:, security_deposit_amount:)
        @id                      = id
        @title                   = title
        @description             = description
        @lat                     = lat
        @lng                     = lng
        @address                 = address
        @postal_code             = postal_code
        @check_in_time           = check_in_time
        @check_out_time          = check_out_time
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
