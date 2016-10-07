module JTB
  module Repositories
    # +StateRepository+
    #
    # Persistence operations and queries of the +jtb_state+ table.
    class StateRepository
      include Hanami::Repository

      def self.by_prefix(prefix)
        query do
          where(prefix: prefix)
        end.first
      end

      def self.upsert(prefix, file_name)
        HotelRepository.adapter.instance_variable_get("@connection")[
          "insert into jtb_state (prefix, file_name) values
           (:prefix, :file_name)
           on conflict (prefix) do update set file_name = :file_name",
          {
            prefix: prefix,
            file_name: file_name
          }
        ].first
      end
    end
  end
end

