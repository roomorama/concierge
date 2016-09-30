module JTB
  module Entities
    class RoomPrice
      include Hanami::Entity

      attributes :city_code, :hotel_code, :rate_plan_id, :date, :room_rate
    end
  end
end
