module JTB
  module Repositories
    # +RoomPriceRepository+
    #
    # Persistence operations and queries of the +jtb_room_prices+ table.
    class RoomPriceRepository
      include Hanami::Repository

      def self.copy_csv_into
        RoomStockRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_room_prices,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end

      def self.room_min_price(room, rate_plans, date)
        query do
          where(rate_plan_id: rate_plans.map(&:rate_plan_id))
            .and(city_code: room.city_code)
            .and(hotel_code: room.hotel_code)
            .and(date: date)
        end.min(:room_rate)
      end
    end
  end
end

