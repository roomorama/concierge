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
          .and("sale_status != '0'")
        end
      end
    end
  end
end

