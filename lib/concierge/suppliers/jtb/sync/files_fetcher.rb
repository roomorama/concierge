module JTB
  module Sync
    # +JTB::FilesFetcher+
    # Class responsible for downloading files required for JTB sync processes.
    #
    class FilesFetcher

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      # Fetches files and saves them in tmp_path
      def fetch_files
        FileUtils.mkdir(options['tmp_path']) unless File.exists? options['tmp_path']
        download_files
      end

      def cleanup
        path = Dir.glob(File.join(options['tmp_path'], '*'))
        FileUtils.rm_rf(path)
      end

      private

      def sftp
        Net::SFTP.start(
          options['host'], options['user_id'], password: options['password'], port: options['port']
        ) do |session|
           return yield(session)
        end
      end

      def download_files
        # fetch('HotelInfo_ALL')
        fetch('RoomType_ALL')
        # fetch('PictureMaster_ALL')
        # fetch('RoomPrice_ALL')
        # fetch('RoomPlan_ALL')
        # fetch('GenericMaster_ALL')
        # Too large file
        # fetch('RoomStock_ALL')
      end

      def fetch(file_name)
        sftp do |session|
          dest = File.join(options['tmp_path'], file_name)
          session.download!(get_full_name(file_name), dest)
          unzip_csv_file(dest)
        end
      end

      def get_full_name(prefix)
        list_files.find { |file| file.start_with?(prefix) }
      end

      def list_files
        sftp do |session|
          files = session.dir.entries('/')
          files.map(&:name)
        end
      end

      def options
        credentials.sftp
      end

      def unzip_csv_file(file_name)
        `cd #{options['tmp_path']} && unzip -o #{file_name}`
      end
    end
  end
end
