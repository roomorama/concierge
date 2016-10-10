module JTB
  module Sync
    module DB
      # +JTB::Sync::HotelsActualizer+
      #
      # Class responsible for actualizing DB jtb_hotels table
      class HotelsActualizer < BaseActualizer

        FILE_PREFIX = 'HotelInfo'

        # mapping between CSV columns and DB table columns,
        MAPPING = {
          0   => :language,
          1   => :city_code,
          2   => :hotel_code,
          3   => :jtb_hotel_code,
          6   => :hotel_name,
          9   => :location_code,
          10  => :hotel_description,
          19  => :latitude,
          20  => :longitude,
          22  => :hotel_type,
          24  => :address,
          37  => :non_smoking_room,
          71  => :parking,
          108 => :internet,
          112 => :wifi,
          123 => :indoor_pool_free,
          130 => :indoor_pool_charged,
          137 => :outdoor_pool_free,
          144 => :outdoor_pool_charged,
          128 => :indoor_gym_free,
          135 => :indoor_gym_charged,
          142 => :outdoor_gym_free,
          149 => :outdoor_gym_charged,
          165 => :wheelchair_access
        }

        UPDATE_CATEGORY_INDEX = 280

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

        def file_prefix
          FILE_PREFIX
        end

        def repository
          JTB::Repositories::HotelRepository
        end

        private

        def extract_update_category(line)
          line.split(CSV_DELIMITER, -1)[UPDATE_CATEGORY_INDEX].to_i
        end

        def build_attributes(line, columns_mapping)
          # Remove last \n from string
          line = line[0..-2]

          splitted = line.split(CSV_DELIMITER, -1).map { |e| e.empty? ? nil : e }

          columns_mapping.map do |k, v|
            [v, splitted[k]]
          end.to_h
        end

        def fetch_required_columns(line, indexes)
          # Remove last \n from string
          line = line[0..-2]
          line.split(CSV_DELIMITER, -1).values_at(*indexes).join(CSV_DELIMITER) + "\n"
        end
      end
    end
  end
end
