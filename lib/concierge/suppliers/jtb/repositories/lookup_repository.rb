module JTB
  module Repositories
    # +LookupRepository+
    #
    # Persistence operations and queries of the +jtb_lookups+ table.
    class LookupRepository
      include Hanami::Repository

      def self.copy_csv_into
        PictureRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_lookups,
          format: :csv,
          # Actually this is hack. We use quote symbol which (hopefully) never
          # meet in file. JTB does not use quote at all while COPY command requires it for CSV
          # we can not use default '"' symbol because it is often part of comment
          # field.
          options: "DELIMITER '\t'"
        ) { yield }
      end
    end
  end
end

