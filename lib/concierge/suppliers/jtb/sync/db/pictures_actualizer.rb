module JTB
  module Sync
    module DB
      # +JTB::Sync::PicturesActualizer+
      #
      # Class responsible for actualizing DB jtb_pictures table
      class PicturesActualizer < BaseActualizer

        FILE_PREFIX = 'PictureMaster'

        # mapping between CSV columns and DB table columns,
        MAPPING = {
          0 => :language,
          1 => :city_code,
          2 => :hotel_code,
          3 => :sequence,
          4 => :category,
          5 => :room_code,
          7 => :url,
          8 => :comments
        }

        UPDATE_CATEGORY_INDEX = 10

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
          JTB::Repositories::PictureRepository
        end

        private

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
      end
    end
  end
end
