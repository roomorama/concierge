module JTB
  module Entities
    class RoomStock
      include Hanami::Entity

      attributes :language, :hotel_code, :option_plan_id, :service_date, :number_of_units,
                 :closing_date, :sale_status, :reservation_closing_date
    end
  end
end
