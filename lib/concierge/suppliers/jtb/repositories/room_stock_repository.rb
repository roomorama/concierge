module JTB
  module Repositories
    # +RoomStockRepository+
    #
    # Persistence operations and queries of the +jtb_room_stocks+ table.
    class RoomStockRepository
      include Hanami::Repository

      def self.copy_csv_into
        RoomStockRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_room_stocks,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end

      def self.actual_availabilities(rate_plans, from, to)
        query do
          where(rate_plan_id: rate_plans.map(&:rate_plan_id))
          .and("service_date between '#{from}' and '#{to}'")
          .and('number_of_units > 0')
          .and("sale_status = '0'")
        end
      end

      def self.availabilities(rate_plans, from, to)
        query do
          where(rate_plan_id: rate_plans.map(&:rate_plan_id))
            .and("service_date between '#{from}' and '#{to}'")
        end
      end

      def self.by_primary_key(city_code, hotel_code, rate_plan_id, service_date)
        query do
          where(city_code: city_code)
            .and(hotel_code: hotel_code)
            .and(rate_plan_id: rate_plan_id)
            .and(service_date: service_date)
        end.first
      end

      def self.upsert(attributes)
        HotelRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_room_stocks
           (
             city_code,
             hotel_code,
             rate_plan_id,
             service_date,
             number_of_units,
             closing_date,
             sale_status,
             reservation_closing_date
           ) values (
             :city_code,
             :hotel_code,
             :rate_plan_id,
             :service_date,
             :number_of_units,
             :closing_date,
             :sale_status,
             :reservation_closing_date
           )
           on conflict (
             city_code,
             hotel_code,
             rate_plan_id,
             service_date
           ) do update set
             number_of_units = :number_of_units,
             closing_date = :closing_date,
             sale_status = :sale_status,
             reservation_closing_date = :reservation_closing_date
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        RoomStockRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_room_stocks
           where city_code = :city_code
             and hotel_code = :hotel_code
             and rate_plan_id = :rate_plan_id
             and service_date = :service_date
          ',
          attributes
        ].first
      end
    end
  end
end

