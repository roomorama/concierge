module JTB
  module Repositories
    # +RoomTypeRepository+
    #
    # Persistence operations and queries of the +jtb_room_types+ table.
    class RoomTypeRepository
      include Hanami::Repository

      def self.copy_csv_into
        RoomTypeRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_room_types,
          format: :csv,
          options: "DELIMITER '\t'"
        ) { yield }
      end

      def self.hotel_english_rooms(city_code, hotel_code)
        query do
          where(language: 'EN')
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
        end
      end

      def self.by_code(room_code)
        query do
          where(language: 'EN')
            .and(room_code: room_code)
        end.first
      end

      def self.by_primary_key(language, city_code, hotel_code, room_code)
        query do
          where(language: language)
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
            .and(room_code: room_code)
        end.first
      end

      def self.upsert(attributes)
        RoomTypeRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_room_types
           (
             language,
             city_code,
             hotel_code,
             room_code,
             room_grade,
             room_type_code,
             room_name,
             min_guests,
             max_guests,
             extra_bed,
             extra_bed_type,
             size1,
             size2,
             size3,
             size4,
             size5,
             size6,
             amenities
           ) values (
             :language,
             :city_code,
             :hotel_code,
             :room_code,
             :room_grade,
             :room_type_code,
             :room_name,
             :min_guests,
             :max_guests,
             :extra_bed,
             :extra_bed_type,
             :size1,
             :size2,
             :size3,
             :size4,
             :size5,
             :size6,
             :amenities
           )
           on conflict (
             language,
             city_code,
             hotel_code,
             room_code
           ) do update set
              room_grade = :room_grade,
              room_type_code = :room_type_code,
              room_name = :room_name,
              min_guests = :min_guests,
              max_guests = :max_guests,
              extra_bed = :extra_bed,
              extra_bed_type = :extra_bed_type,
              size1 = :size1,
              size2 = :size2,
              size3 = :size3,
              size4 = :size4,
              size5 = :size5,
              size6 = :size6,
              amenities = :amenities
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        RoomTypeRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_room_types
           where language = :language
             and city_code = :city_code
             and hotel_code = :hotel_code
             and room_code = :room_code
          ',
          attributes
        ].first
      end
    end
  end
end

