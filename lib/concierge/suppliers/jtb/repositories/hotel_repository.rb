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
          # Actually this is hack. We use quote symbol which (hopefully) never
          # meet in file. JTB does not use quote at all while COPY command requires it for CSV
          # we can not use default '"' symbol because it is often part of description
          # field.
          options: "DELIMITER '\t', QUOTE E'\b'"
        ) { yield }
      end
    end
  end
end

