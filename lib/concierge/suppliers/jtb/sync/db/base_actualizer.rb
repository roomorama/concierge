module JTB
  module Sync
    module DB
      # +JTB::Sync::BaseActualizer+
      #
      # Class responsible for actualizing DB JTB tables.
      # It tries to find (by prefix) files for appropriate table in tmp_path directory and imports them to DB.
      # There are two kinds of files:
      #   * ALL - file contains all the data from JTB, before import such files the actualizer clear DB table
      #   * Diff - file contains only diff information. The actualizer applies this diff to current DB table.
      #
      # If import finishes successful last synced file for given file_prefix will be saved to jtb_state table.
      #
      # +JTB::Sync::FileActualizer+ responsible for fetching files from JTB server and saving them to tmp_path
      # directory.

      # Each descendant has to implement next methods:
      #  * file_prefix
      #  * import_file
      #  * repository
      # See details in methods' docs.
      #
      # Also descendant can implement:
      #  * error_result - to add error details
      #  * import_diff_file - if there are diff files for the table
      #
      # It is highly desirable that all descendant implement each file import in
      # transaction, to avoid situation when only part of file imported.
      #
      # Usage:
      #
      # class HotelsActualizer < BaseActualizer
      #   ...
      # end
      #
      # hotels_actualizer = HotelsActualizer.new(tmp_path)
      # result = hotels_actualizer.actualize
      #
      # if result.success?
      #   JTB::Repositories::HotelRepository.all # all hotels from files
      # end
      #
      class BaseActualizer

        CSV_DELIMITER = "\t"

        attr_reader :tmp_path

        def initialize(tmp_path)
          @tmp_path = tmp_path
        end

        def actualize
          all_file = find_all_file_path
          if all_file
            cleanup
            import_file(all_file)

            save_state(all_file)
          end

          diff_files = find_diff_files
          diff_files.each do |file_path|
            import_diff_file(file_path)
            save_state(file_path)
          end
          Result.new(true)
        rescue => e
          error_result
        end

        # Returns prefix of filename to be looking for in tmp_path directory and imported to DB.as string
        def file_prefix
          raise NotImplementedError
        end

        protected

        def error_result
          Result.error(
            :jtb_db_actualization_error,
            "Error during import file with prefix `#{file_prefix}` to DB"
          )
        end

        # Performs import of ALL files.
        def import_file(file_path)
          raise NotImplementedError
        end

        # Performs import of Diff files.
        def import_diff_file(file_path)
          raise NotImplementedError
        end

        # Returns repository class to work with appropriate DB table.
        def repository
          raise NotImplementedError
        end

        def cleanup
          repository.clear
        end

        private

        def save_state(file_path)
          file_name = File.basename(file_path).sub('csv', 'zip')
          JTB::Repositories::StateRepository.upsert(file_prefix, file_name)
        end


        def find_all_file_path
          Dir.glob(File.join(tmp_path, "#{file_prefix}_ALL_*.csv")).sort_by do |filename|
            created_time(filename)
          end.first
        end

        def find_diff_files
          Dir.glob(File.join(tmp_path, "#{file_prefix}_Diff_*.csv")).sort_by do |filename|
            created_time(filename)
          end
        end

        def created_time(filename)
          time_str = filename.split('_').last.split('.').first
          DateTime.parse(time_str)
        end
      end
    end
  end
end