module JTB
  module Sync
    # +JTB::Actualizer+
    # Class responsible for actualizing JTB DB tables required to run JTB sync workers.
    #
    # It fetches required CSV files from JTB server and imports them to DB.
    # Interrupt the process and return unsuccess result if error occurs during some table actualization.
    class Actualizer

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
        @db_actualizers = [
          DB::HotelsActualizer.new(tmp_path),
          DB::LookupsActualizer.new(tmp_path),
          DB::PicturesActualizer.new(tmp_path),
          DB::RatePlansActualizer.new(tmp_path),
          DB::RoomTypesActualizer.new(tmp_path),
          DB::RoomPricesActualizer.new(tmp_path),
          DB::RoomStocksActualizer.new(tmp_path)
        ]
      end

      def actualize
        @db_actualizers.each do |db_actualizer|
          result = actualize_table(db_actualizer)
          return result unless result.success?
        end

        Result.new(true)
      end

      private

      def actualize_table(db_actualizer)
        last_synced = fetch_last_synced(db_actualizer.file_prefix)
        file_actualizer = FileActualizer.new(credentials, db_actualizer.file_prefix)
        result = file_actualizer.actualize(last_synced&.file_name)
        return result unless result.success?

        result = db_actualizer.actualize
        # file_actualizer.cleanup returns Result, but it's not so important if it is not success
        file_actualizer.cleanup

        result
      end

      def tmp_path
        @tmp_path ||= credentials.sftp['tmp_path']
      end

      def fetch_last_synced(file_prefix)
        JTB::Repositories::StateRepository.by_prefix(file_prefix)
      end
    end
  end
end