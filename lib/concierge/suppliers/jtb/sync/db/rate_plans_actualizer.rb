module JTB
  module Sync
    module DB
      # +JTB::Sync::RatePlansActualizer+
      #
      # Class responsible for actualizing DB jtb_rate_plans table
      class RatePlansActualizer < BaseActualizer

        FILE_PREFIX = 'RoomPlan'

        # mapping between CSV columns and DB table columns,
        MAPPING = {
          1 => :city_code,
          2 => :hotel_code,
          3 => :rate_plan_id,
          4 => :room_code,
          5 => :meal_plan_code,
          6 => :occupancy
        }

        UPDATE_CATEGORY_INDEX = 39
        LANGUAGE_COLUMN_INDEX = 0


        def file_prefix
          FILE_PREFIX
        end

        protected

        def import_file(file_path)
          File.open(file_path) do |file|
            indexes = MAPPING.keys
            repository.copy_csv_into do
              # We need only price info from this file
              # so language is not important. Will take only english.
              line = read_english_line(file)
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
                if english?(line)
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
        end

        def repository
          JTB::Repositories::RatePlanRepository
        end

        private

        def english?(line)
          line.split(CSV_DELIMITER, -1)[LANGUAGE_COLUMN_INDEX] == 'EN'
        end

        def extract_update_category(line)
          line.split(CSV_DELIMITER, -1)[UPDATE_CATEGORY_INDEX].to_i
        end

        def build_attributes(line, columns_mapping)
          # Remove last \n from string
          line = line[0..-2]

          # postgresql copy into write empty strings as NULL.
          # To make Diff import the same replace all empty strings with nil
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

        # Returns next english line from file or nil
        # Used for filtering out not english lines
        def read_english_line(file)
          line = file.gets
          while line && !english?(line)
            line = file.gets
          end
          line
        end
      end
    end
  end
end
