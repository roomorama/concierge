module JTB
  module Sync
    module DB
      # +JTB::Sync::BaseActualizer+
      #
      # Class responsible for actualizing DB JTB tables
      class BaseActualizer

        CSV_DELIMETER = "\t"

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
        rescue Object => e
          Result.error(:error_during_jtb_db_actualisation)
        end

        protected

        def import_file(file_path)
          raise NotImplementedError
        end

        def import_diff_file(file_path)
          raise NotImplementedError
        end

        def file_prefix
          raise NotImplementedError
        end

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