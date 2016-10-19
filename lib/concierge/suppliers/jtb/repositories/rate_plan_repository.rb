module JTB
  module Repositories
    # +RatePlanRepository+
    #
    # Persistence operations and queries of the +jtb_rate_plans+ table.
    class RatePlanRepository
      include Hanami::Repository

      def self.copy_csv_into
        RatePlanRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_rate_plans,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end

      def self.room_rate_plans(room)
        query do
          where(room_code: room.room_code)
            .and(city_code: room.city_code)
            .and(hotel_code: room.hotel_code)
        end
      end

      def self.by_room_code(room_code)
        query do
          where(room_code: room_code)
        end
      end

      def self.by_primary_key(city_code, hotel_code, rate_plan_id)
        query do
          where(rate_plan_id: rate_plan_id)
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
        end.first
      end

      def self.upsert(attributes)
        RatePlanRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_rate_plans
           (
             city_code,
             hotel_code,
             rate_plan_id,
             room_code,
             meal_plan_code,
             occupancy
           ) values (
             :city_code,
             :hotel_code,
             :rate_plan_id,
             :room_code,
             :meal_plan_code,
             :occupancy
           )
           on conflict (
             city_code,
             hotel_code,
             rate_plan_id
           ) do update set
             room_code = :room_code,
             meal_plan_code = :meal_plan_code,
             occupancy = :occupancy
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        RatePlanRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_rate_plans
           where rate_plan_id = :rate_plan_id
             and city_code = :city_code
             and hotel_code = :hotel_code
          ',
          attributes
        ].first
      end
    end
  end
end

