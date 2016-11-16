module JTB
  module Entities
    class Hotel
      include Hanami::Entity

      attributes :language, :city_code, :hotel_code, :jtb_hotel_code, :hotel_name,
                 :location_code, :hotel_description, :latitude, :longitude, :hotel_type,
                 :address, :non_smoking_room, :parking, :internet, :wifi, :indoor_pool_free,
                 :indoor_pool_charged, :outdoor_pool_free, :outdoor_pool_charged, :indoor_gym_free,
                 :indoor_gym_charged, :outdoor_gym_free, :outdoor_gym_charged, :wheelchair_access,
                 :check_in, :check_out

      def has_pool?
        indoor_pool_free == '1' ||
          indoor_pool_charged == '1' ||
          outdoor_pool_free == '1' ||
          outdoor_pool_charged == '1'
      end

      def has_gym?
        indoor_gym_free == '1' ||
          indoor_gym_charged == '1' ||
          outdoor_gym_free == '1' ||
          outdoor_gym_charged == '1'
      end
    end
  end
end
