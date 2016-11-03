module JTB
  module Sync
    # +JTB::FilesFetcher+
    # Class responsible for downloading files required for JTB sync processes.
    #
    # There are two kinds of files:
    #   * ALL - file contains all the data from JTB
    #   * Diff - file contains only diff information
    #
    # Before start it removes files with appropriate prefix from tmp_path directory.
    # Then it builds list of files to be downloaded by next rules:
    # - if this is first sync (last_synced is nil) it downloads last ALL file and all Diff files after him
    # - if last synced file exists on SFTP server it downloads Diff files after last
    # - if last synced file not exists on SFTP server it behaves like first sync
    class FileActualizer

      attr_reader :credentials, :file_prefix

      def initialize(credentials, file_prefix)
        @credentials = credentials
        @file_prefix = file_prefix
      end

      def actualize(last_synced, force_all = false)
        prepare_tmp_dir

        result = required_files(last_synced, force_all)

        return result unless result.success?

        result.value.each do |file_path|
          fetch_file(file_path)
        end

        close
        Result.new(true)
      rescue => e
        begin
          cleanup
        rescue ::Exception
          # swallow exceptions that occur while trying to cleanup
        end
        begin
          shutdown
        rescue ::Exception
          # swallow exceptions that occur while trying to shutdown
        end
        Result.error(
          :actualize_file_error,
          "Error during actualizing files with prefix `#{file_prefix}`. #{e.message}"
        )
      end

      def cleanup
        path = File.join(options['tmp_path'], "#{file_prefix}*")
        return Result.error(:jtb_file_cleanup_error, "Forbidden to delete files from `#{path}`") if path == '/*'

        files = Dir.glob(path)
        FileUtils.rm_rf(files)
        Result.new(true)
      rescue => e
        Result.error(
          :jtb_file_cleanup_error,
          "Error during cleaning up files with prefix `#{file_prefix}`. #{e.message}")
      end

      private

      def prepare_tmp_dir
        if File.exists?(options['tmp_path'])
          cleanup
        else
          FileUtils.mkdir(options['tmp_path'])
        end
      end

      # Returns list of file paths required to be downloaded from the sftp server
      # to make DB actual.
      def required_files(last_synced, force_all)
        files = []

        if !force_all && last_synced && file_exists?(last_synced)
          time = created_time(last_synced)
        else
          last_all_filepath = fetch_last_all_filepath

          return Result.error(
            :all_file_not_found,
            "'ALL' file not found for prefix #{file_prefix}"
          ) unless last_all_filepath

          time = created_time(last_all_filepath)

          if !last_synced || time > created_time(last_synced)
            files << last_all_filepath
          end
        end

        Result.new(files + fetch_diffs_after(time))
      end

      # Should be closed with close or shutdown method
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
        []
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
