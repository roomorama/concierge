module JTB
  module Repositories
    # +PictureRepository+
    #
    # Persistence operations and queries of the +jtb_pictures+ table.
    class PictureRepository
      include Hanami::Repository

      def self.copy_csv_into
        PictureRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_pictures,
          format: :csv,
          # Actually this is hack. We use quote symbol which (hopefully) never
          # meet in file. JTB does not use quote at all while COPY command requires it for CSV
          # we can not use default '"' symbol because it is often part of comment
          # field.
          options: "DELIMITER '\t', QUOTE E'\b'"
        ) { yield }
      end

      def self.hotel_english_images(city_code, hotel_code)
        query do
          # 999 is the tour category code, we don't want tour pictures
          where("category != '999'")
            .and(language: 'EN')
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
            .and('room_code is null')
        end
      end

      def self.room_english_images(room_code)
        query do
          # 999 is the tour category code, we don't want tour pictures
          where("category != '999'")
            .and(language: 'EN')
            .and(room_code: room_code)
        end
      end

      def self.by_primary_key(language, city_code, hotel_code, sequence)
        query do
          where(language: language)
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
            .and(sequence: sequence)
        end.first
      end

      def self.upsert(attributes)
        PictureRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_pictures
           (
             language,
             city_code,
             hotel_code,
             sequence,
             category,
             room_code,
             url,
             comments
           ) values (
             :language,
             :city_code,
             :hotel_code,
             :sequence,
             :category,
             :room_code,
             :url,
             :comments
           )
           on conflict (
             language,
             city_code,
             hotel_code,
             sequence
           ) do update set
              category = :category,
              room_code = :room_code,
              url = :url,
              comments = :comments
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        PictureRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_pictures
           where language = :language
             and city_code = :city_code
             and hotel_code = :hotel_code
             and sequence = :sequence
          ',
          attributes
        ].first
      end
    end
  end
end

