module JTB
  module Sync
    module DB
      # +JTB::Sync::RoomTypesActualizer+
      #
      # Class responsible for actualizing DB jtb_room_types table
      class RoomTypesActualizer < BaseActualizer

        FILE_PREFIX = 'RoomType'

        # mapping between CSV columns and DB table columns,
        MAPPING = {
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
        }

        UPDATE_CATEGORY_INDEX = 123

        def file_prefix
          FILE_PREFIX
        end

        protected

        def import_file(file_path)
          File.open(file_path) do |file|
            indexes = MAPPING.keys
            repository.copy_csv_into do
              line = file.gets
              fetch_required_columns(line, indexes) if line
            end
          end
        end

        def import_diff_file(file_path)
          File.open(file_path) do |file|
            # Use savepoint here to be sure of new transaction.
            # Because by default Sequel will reuse an existing transaction
            repository.transaction(rollback: :reraise, savepoint: true) do
              file.each_line do |line|
                attributes = build_attributes(line, MAPPING)
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

        def repository
          JTB::Repositories::RoomTypeRepository
        end

        private

        def extract_update_category(line)
          line.split(CSV_DELIMITER, -1)[UPDATE_CATEGORY_INDEX].to_i
        end

        def build_attributes(line, columns_mapping)
          # Remove last \n from string
          line = line[0..-2]

          # postgresql copy into writes empty strings as NULL.
          # To make Diff import the same replace all empty strings with nil
          splitted = line.split(CSV_DELIMITER, -1).map { |e| e.empty? ? nil : e }

          attributes = columns_mapping.map do |k, v|
            [v, splitted[k]]
          end.to_h
          attributes[:amenities] = fetch_amenities(line)

          attributes
        end

        def fetch_required_columns(line, indexes)
          # Remove last \n from string
          line = line[0..-2]
          values = line.split(CSV_DELIMITER, -1)
          required_columns = values.values_at(*indexes).map { |e| e.empty? ? nil : e }
          compressed_amenities = fetch_amenities(line)
          required_columns << compressed_amenities

          required_columns.join(CSV_DELIMITER) + "\n"
        end

        def fetch_amenities(line)
          values = line.split(CSV_DELIMITER, -1)
          # File contains 100 amenities columns with values '1', '0' or ''
          # let's join all amenities values in one
          values[23..122].map { |a| a.to_s.empty? ? ' ' : a.to_s }.join
        end
      end
    end
  end
end
