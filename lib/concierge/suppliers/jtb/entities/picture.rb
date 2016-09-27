module JTB
  module Entities
    class Picture
      include Hanami::Entity

      attributes :language, :city_code, :hotel_code, :sequence, :category, :room_code,
                 :url, :comments
    end
  end
end
