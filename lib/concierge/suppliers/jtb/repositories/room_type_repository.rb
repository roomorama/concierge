module JTB
  module Repositories
    # +RoomTypeRepository+
    #
    # Persistence operations and queries of the +jtb_room_types+ table.
    class RoomTypeRepository
      include Hanami::Repository

      def self.copy_csv_into
        RoomTypeRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_room_types,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end
    end
  end
end

