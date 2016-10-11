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

      def self.by_primary_key(city_code, hotel_code, rate_plan_id, date)
        query do
          where(city_code: city_code)
            .and(hotel_code: hotel_code)
            .and(rate_plan_id: rate_plan_id)
            .and(date: date)
        end.first
      end

      def self.upsert(attributes)
        RoomPriceRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_room_prices
           (
             city_code,
             hotel_code,
             rate_plan_id,
             date,
             room_rate
           ) values (
             :city_code,
             :hotel_code,
             :rate_plan_id,
             :date,
             :room_rate
           )
           on conflict (
             city_code,
             hotel_code,
             rate_plan_id,
             date
           ) do update set
             room_rate = :room_rate
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        RoomPriceRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_room_prices
           where city_code = :city_code
             and hotel_code = :hotel_code
             and rate_plan_id = :rate_plan_id
             and date = :date
          ',
          attributes
        ].first
      end
    end
  end
end

