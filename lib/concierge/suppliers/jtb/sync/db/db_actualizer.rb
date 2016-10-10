module JTB
  module Sync
      module DB
      # +JTB::Sync::DBActualizer+
      #
      # Class responsible for actualizing DB JTB tables
      class DBActualizer

        # Keys - file prefixes.
        # Values - configurations for each file:
        #   columns_mapping - mapping between CSV columns and DB table columns,
        #   repository - repository class for the file's model. It should implement
        #                +copy_csv_into+ for ALL file import,
        #                +upsert+ for Diff file import
        #                +delete+ for Diff file import
        #   update_category_index - index of Diff CSV file column with information about
        #                            Diff type (New, Updated, Deleted)
        #   entity - entity class
        SUPPORTED_FILES = {
          'RoomPrice' => {
            'columns_mapping' => [
              0 => :city_code,
              1 => :hotel_code,
              2 => :rate_plan_id,
              3 => :date,
              4 => :room_rate
            ],
            'repository' => JTB::Repositories::RoomPriceRepository,
            'update_category_index' => 21,
          },
          'RoomStock' => {
            'columns_mapping' => [
              0 => :language,
              1 => :hotel_code,
              2 => :option_plan_id,
              3 => :service_date,
              4 => :number_of_units,
              5 => :closing_date,
              6 => :sale_status,
              7 => :reservation_closing_date,
            ],
            'repository' => JTB::Repositories::RoomStockRepository,
            'update_category_index' => 8,
          },
          'RoomType' => {
            'columns_mapping' => [
              0  => :language,
              1  => :city_code,
              2  => :hotel_code,
              3  => :room_code,
              4  => :room_grade,
              5  => :room_type_code,
              6  => :room_name,
              11 => :min_guests,
              12 => :max_guests,
              13 => :extra_bed,
              14 => :extra_bed_type,
              15 => :size1,
              16 => :size2,
              17 => :size3,
              18 => :size4,
              19 => :size5,
              20 => :size6,
            ],
            'repository' => JTB::Repositories::RoomTypeRepository,
            'update_category_index' => 123,
          }
        }

        RATE_PLAN_LANGUAGE_COLUMN_INDEX = 0

        attr_reader :tmp_path, :file_prefix, :repository, :columns_mapping,
                    :update_category_index

        def initialize(tmp_path, file_prefix)
          # TODO: handle the case more elegant
          raise Exception unless SUPPORTED_FILES.key?(file_prefix)

          @tmp_path = tmp_path
          @file_prefix = file_prefix

          @repository            = SUPPORTED_FILES[file_prefix]['repository']
          @columns_mapping       = SUPPORTED_FILES[file_prefix]['columns_mapping']
          @update_category_index = SUPPORTED_FILES[file_prefix]['update_category_index']
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
        end

        def cleanup
          repository.clear
        end

        private

        CSV_DELIMITER = "\t"

        def save_state(file_path)
          file_name = File.basename(file_path).sub('csv', 'zip')
          JTB::Repositories::StateRepository.upsert(file_prefix, file_name)
        end

        def import_file(file_path)
          case file_prefix
          when 'RoomType' then import_room_types(file_path)
          when 'RoomPlan' then import_rate_plans(file_path)
          else import(file_path)
          end
        end

        def import_diff_file(file_path)
          case file_prefix
            when 'RoomType' then import_diff_room_types(file_path)
            when 'RoomPlan' then import_diff_rate_plans(file_path)
            else import_diff(file_path)
          end
        end

        def import_diff(file_path)
          File.open(file_path) do |file|
            repository.transaction do
              file.each_line do |line|
                attributes = build_attributes(line, columns_mapping)
                update_category = extract_update_category(line)
                if update_category <= 2
                  repository.upsert(attributes)
                else
                  repository.delete(attributes)
                end
              end
            end
          end
        end

        def extract_update_category(line)
          line.split(CSV_DELIMITER, -1)[update_category_index].to_i
        end

        # Usual import algorithm.
        # Opens file and line by line sends data to the DB.
        # No filters, no hooks.
        def import(file_path)
          File.open(file_path) do |file|
            indexes = columns_mapping.keys
            repository.copy_csv_into do
              line = file.gets
              fetch_required_columns(line, indexes) if line
            end
          end
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

        def import_room_types(file_path)
          File.open(file_path) do |file|
            indexes = columns_mapping.keys
            repository.copy_csv_into do
              line = file.gets
              fetch_room_types_required_columns(line, indexes) if line
            end
          end
        end

        def import_rate_plans(file_path)
          File.open(file_path) do |file|
            indexes = columns_mapping.keys
            repository.copy_csv_into do
              # We need only price info from this file
              # so language is not important. Will take only english.
              line = read_english_line(file, RATE_PLAN_LANGUAGE_COLUMN_INDEX)
              fetch_required_columns(line, indexes) if line
            end
          end
        end

        def import_rate_plans_diff(file_path)
          File.open(file_path) do |file|
            repository.transaction do
              file.each_line do |line|
                attributes = build_attributes(line, columns_mapping)
                update_category = extract_update_category(line)
                if update_category <= 2
                  repository.upsert(attributes)
                else
                  repository.delete(attributes)
                end
              end
            end
          end
        end

        def build_attributes(line, columns_mapping)
          # Remove last \n from string
          line = line[0..-2]

          splitted = line.split(CSV_DELIMITER, -1)

          columns_mapping.map do |k, v|
            [v, splitted[k]]
          end.to_h
        end

        def fetch_required_columns(line, indexes)
          # Remove last \n from string
          line = line[0..-2]
          line.split(CSV_DELIMITER, -1).values_at(*indexes).join(CSV_DELIMITER) + "\n"
        end

        def fetch_room_types_required_columns(line, indexes)
          # Remove last \n from string
          line = line[0..-2]
          values = line.split(CSV_DELIMITER, -1)
          required_columns = values.values_at(*indexes)
          # File contains 100 amenities columns with values '1', '0' and ''
          # let's join all amenities values in one
          compressed_amenities = values[23..122].map { |a| a.to_s.empty? ? ' ' : a.to_s }.join
          required_columns << compressed_amenities

          required_columns.join(CSV_DELIMITER) + "\n"
        end

        # Returns next english line from file or nil
        # Used for filtering out not english lines
        def read_english_line(file, language_column_index)
          line = file.gets
          while line && !english?(line, language_column_index)
            line = file.gets
          end
          line
        end

        def english?(line, language_column_index)
          line.split(CSV_DELIMITER, -1)[language_column_index] == 'EN'
        end
      end
    end
  end
end