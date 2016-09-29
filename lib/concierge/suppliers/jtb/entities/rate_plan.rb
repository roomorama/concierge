module JTB
  module Entities
    class RatePlan
      include Hanami::Entity

      attributes :language, :city_code, :hotel_code, :rate_plan_id, :room_code, :meal_plan_code, :occupancy
    end
  end
end
