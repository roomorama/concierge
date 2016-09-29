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

      def self.hotel_english_rooms(city_code, hotel_code)
        query do
          where(language: 'EN')
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
        end
      end
    end
  end
end

