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
    end
  end
end

