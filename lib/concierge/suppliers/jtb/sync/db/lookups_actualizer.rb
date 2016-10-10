module JTB
  module Sync
    module DB
      # +JTB::Sync::LookupActualizer+
      #
      # Class responsible for actualizing DB jtb_lookups table
      # JTB does not provide Diff files for GenericMaster, so
      # the class doesn't implement +import_diff_file+
      # In case of appearance of Diff file we will see exception
      # from +BaseActualizer+
      class LookupsActualizer < BaseActualizer

        FILE_PREFIX = 'GenericMaster'

        # mapping between CSV columns and DB table columns,
        MAPPING = {
          0 => :language,
          1 => :category,
          3 => :id,
          4 => :related_id,
          5 => :name
        }

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

        def file_prefix
          FILE_PREFIX
        end

        def repository
          JTB::Repositories::LookupRepository
        end

        private

        def fetch_required_columns(line, indexes)
          # Remove last \n from string
          line = line[0..-2]
          line.split(CSV_DELIMITER, -1).values_at(*indexes).join(CSV_DELIMITER) + "\n"
        end
      end
    end
  end
end
