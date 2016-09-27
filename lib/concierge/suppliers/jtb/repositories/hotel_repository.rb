module JTB
  module Repositories
    # +RoomTypeRepository+
    #
    # Persistence operations and queries of the +jtb_hotels+ table.
    class HotelRepository
      include Hanami::Repository

      def self.copy_csv_into
        HotelRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_hotels,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end
    end
  end
end

