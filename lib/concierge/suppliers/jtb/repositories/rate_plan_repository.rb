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
    end
  end
end

