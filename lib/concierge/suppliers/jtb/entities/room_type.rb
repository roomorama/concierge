module JTB
  module Entities
    class RoomType
      include Hanami::Entity

      attributes :language, :city_code, :hotel_code, :room_code, :room_grade, :room_type_code, :room_name,
                 :min_guests, :max_guests, :extra_bed, :extra_bed_type, :size1, :size2, :size3, :size4,
                 :size5, :size6, :amenities
    end
  end
end
