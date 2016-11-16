module JTB
  module Repositories
    # +LookupRepository+
    #
    # Persistence operations and queries of the +jtb_lookups+ table.
    class LookupRepository
      include Hanami::Repository

      def self.copy_csv_into
        LookupRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_lookups,
          format: :csv,
          # Actually this is hack. We use quote symbol which (hopefully) never
          # meet in file. JTB does not use quote at all while COPY command requires it for CSV
          # we can not use default '"' symbol because it can be a part of name field.
          options: "DELIMITER '\t', QUOTE E'\b'"
        ) { yield }
      end

      def self.location_name(id)
        query do
          where(category: '1')
            .and(id: id)
            .and(language: 'EN')
          .limit(1)
        end.first
      end

      def self.room_amenity(id)
        query do
          where(category: '19')
            .and(id: id)
            .and(language: 'EN')
          .limit(1)
        end.first
      end

      # Standart Hanami's create  and update can not work with entities which have
      # id column as not primary key.
      def self.upsert(attributes)
        LookupRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_lookups
         (
           language,
           category,
           id,
           related_id,
           name
         ) values (
           :language,
           :category,
           :id,
           :related_id,
           :name
         )
         on conflict (
           language,
           category,
           id
         ) do update set
            related_id = :related_id,
            name = :name
        ',
          attributes
        ].first
      end

      def self.room_grade(id)
        query do
          where(category: '4')
            .and(id: id)
            .and(language: 'EN')
            .limit(1)
        end.first
      end

      def self.by_primary_key(language, category, id)
        query do
          where(language: language)
            .and(category: category)
            .and(id: id)
        end.first
      end
    end
  end
end

