module JTB
  module Sync
    # +JTB::Actualizer+
    # Class responsible for actualizing all data required to run JTB sync workers.
    class Actualizer

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def actualize
        hotels_actualizer = DB::HotelsActualizer.new(tmp_path)
        result = actualize_table(hotels_actualizer)
        return result unless result.success?

        lookups_actualizer = DB::LookupsActualizer.new(tmp_path)
        result = actualize_table(lookups_actualizer)
        return result unless result.success?

        pictures_actualizer = DB::PicturesActualizer.new(tmp_path)
        result = actualize_table(pictures_actualizer)
        return result unless result.success?

        rate_plans_actualizer = DB::RatePlansActualizer.new(tmp_path)
        result = actualize_table(rate_plans_actualizer)
        return result unless result.success?

        room_prices_actualizer = DB::RoomPricesActualizer.new(tmp_path)
        result = actualize_table(room_prices_actualizer)
        return result unless result.success?

        room_stocks_actualizer = DB::RoomStocksActualizer.new(tmp_path)
        result = actualize_table(room_stocks_actualizer)
        return result unless result.success?

        room_types_actualizer = DB::RoomTypesActualizer.new(tmp_path)
        result = actualize_table(room_types_actualizer)
        return result unless result.success?

        Result.new(true)
      end

      private

      def actualize_table(db_actualizer)
        last_synced = fetch_last_synced(db_actualizer.file_prefix)
        file_actualizer = FileActualizer.new(credentials, db_actualizer.file_prefix)
        result = file_actualizer.actualize(last_synced)
        return result unless result.success?

        result = db_actualizer.actualize
        return result unless result.success?

        file_actualizer.cleanup
      end

      def tmp_path
        credentials.sftp['tmp_path']
      end

      def fetch_last_synced(file_prefix)
        JTB::Repositories::StateRepository.by_prefix(file_prefix)
      end
    end
  end
end