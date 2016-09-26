module JTB
  module Repositories
    # +RoomStockRepository+
    #
    # Persistence operations and queries of the +jtb_room_stocks+ table.
    class RoomStockRepository
      include Hanami::Repository

      def self.copy_csv_into
        RoomStockRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_room_stock,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end
    end
  end
end

