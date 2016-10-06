module JTB
  module Sync
    # +JTB::FilesFetcher+
    # Class responsible for downloading files required for JTB sync processes.
    #
    class FileActualizer

      attr_reader :credentials, :file_prefix

      def initialize(credentials, file_prefix)
        @credentials = credentials
        @file_prefix = file_prefix
      end

      def actualize(last_synced)
        if File.exists? options['tmp_path']
          cleanup
        else
          FileUtils.mkdir(options['tmp_path'])
        end

        required_files(last_synced).each do |file_path|
          fetch_file(file_path)
        end
        close
      rescue Object
        begin
          shutdown
        rescue ::Exception
          # swallow exceptions that occur while trying to shutdown
        end
      end

      private

      def cleanup
        path = Dir.glob(File.join(options['tmp_path'], "#{file_prefix}*"))
        FileUtils.rm_rf(path)
      end

      # Should be closed with shutdown method
      def sftp
        @sftp ||= Net::SFTP.start(
          options['host'], options['user_id'], password: options['password'], port: options['port']
        )
      end

      # Hard finishing
      def shutdown
        @sftp&.session&.shutdown!
      end

      # Soft finishing
      def close
        @sftp&.session&.close
      end

      def required_files(last_synced)
        result = []

        if last_synced && file_exists?(last_synced)
          time = created_time(last_synced)
        else
          last_all_filepath = fetch_last_all_filepath
          time = created_time(last_all_filepath)
          result << last_all_filepath
        end

        result + fetch_diffs_after(time)
      end

      def file_exists?(filename)
        !full_filename(filename).nil?
      end

      def full_filename(filename)
        sftp.dir.glob('./', "**/#{filename}").map(&:name).first
      rescue Net::SFTP::StatusException
        nil
      end

      def created_time(filename)
        time_str = filename.split('_').last.split('.').first
        DateTime.parse(time_str)
      end

      def fetch_last_all_filepath
        filenames = sftp.dir.glob('./', "**/#{file_prefix}_ALL_*").map(&:name)
        filenames.max_by { |filename| created_time(filename) }
      rescue Net::SFTP::StatusException
        nil
      end

      def fetch_diffs_after(time)
        filenames = sftp.dir.glob('./', "**/#{file_prefix}_Diff_*").map(&:name)
        filenames.select { |filename| created_time(filename) > time }
      rescue Net::SFTP::StatusException
        nil
      end

      def fetch_file(file_path)
        dest = File.join(options['tmp_path'], File.basename(file_path))
        sftp.download!(file_path, dest)
        unzip_csv_file(dest)
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
