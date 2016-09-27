module JTB
  module Entities
    class Hotel
      include Hanami::Entity

      attributes :language, :city_code, :hotel_code, :jtb_hotel_code, :hotel_name,
                 :location_code, :hotel_description, :latitude, :longitude, :hotel_type,
                 :address, :non_smoking_room, :parking, :internet, :wifi, :indoor_pool_free,
                 :indoor_pool_charged, :outdoor_pool_free, :outdoor_pool_charged, :indoor_gym_free,
                 :indoor_gym_charged, :outdoor_gym_free, :outdoor_gym_charged, :wheelchair_access
    end
  end
end
