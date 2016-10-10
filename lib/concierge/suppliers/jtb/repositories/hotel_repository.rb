module JTB
  module Repositories
    # +HotelRepository+
    #
    # Persistence operations and queries of the +jtb_hotels+ table.
    class HotelRepository
      include Hanami::Repository

      def self.copy_csv_into
        HotelRepository.adapter.instance_variable_get("@connection").copy_into(
          :jtb_hotels,
          format: :csv,
          # Actually this is hack. We use quote symbol which (hopefully) never
          # meet in file. JTB does not use quote at all while COPY command requires it for CSV
          # we can not use default '"' symbol because it is often part of description
          # field.
          options: "DELIMITER '\t', QUOTE E'\b'"
        ) { yield }
      end

      def self.english_ryokans
        query do
          where(language: 'EN').and(hotel_type: 'R')
        end
      end

      def self.by_primary_key(language, city_code, hotel_code)
        query do
          where(language: language)
            .and(city_code: city_code)
            .and(hotel_code: hotel_code)
        end.first
      end

      def self.upsert(attributes)
        HotelRepository.adapter.instance_variable_get("@connection")[
          'insert into jtb_hotels
           (
             language,
             city_code,
             hotel_code,
             jtb_hotel_code,
             hotel_name,
             location_code,
             hotel_description,
             latitude,
             longitude,
             hotel_type,
             address,
             non_smoking_room,
             parking,
             internet,
             wifi,
             indoor_pool_free,
             indoor_pool_charged,
             outdoor_pool_free,
             outdoor_pool_charged,
             indoor_gym_free,
             indoor_gym_charged,
             outdoor_gym_free,
             outdoor_gym_charged,
             wheelchair_access
           ) values (
             :language,
             :city_code,
             :hotel_code,
             :jtb_hotel_code,
             :hotel_name,
             :location_code,
             :hotel_description,
             :latitude,
             :longitude,
             :hotel_type,
             :address,
             :non_smoking_room,
             :parking,
             :internet,
             :wifi,
             :indoor_pool_free,
             :indoor_pool_charged,
             :outdoor_pool_free,
             :outdoor_pool_charged,
             :indoor_gym_free,
             :indoor_gym_charged,
             :outdoor_gym_free,
             :outdoor_gym_charged,
             :wheelchair_access
           )
           on conflict (
             language,
             city_code,
             hotel_code
           ) do update set
              jtb_hotel_code = :jtb_hotel_code,
              hotel_name = :hotel_name,
              location_code = :location_code,
              hotel_description = :hotel_description,
              latitude = :latitude,
              longitude = :longitude,
              hotel_type = :hotel_type,
              address = :address,
              non_smoking_room = :non_smoking_room,
              parking = :parking,
              internet = :internet,
              wifi = :wifi,
              indoor_pool_free = :indoor_pool_free,
              indoor_pool_charged = :indoor_pool_charged,
              outdoor_pool_free = :outdoor_pool_free,
              outdoor_pool_charged = :outdoor_pool_charged,
              indoor_gym_free = :indoor_gym_free,
              indoor_gym_charged = :indoor_gym_charged,
              outdoor_gym_free = :outdoor_gym_free,
              outdoor_gym_charged = :outdoor_gym_charged,
              wheelchair_access = :wheelchair_access
          ',
          attributes
        ].first
      end

      def self.delete(attributes)
        HotelRepository.adapter.instance_variable_get("@connection")[
          'delete from jtb_hotels
           where language = :language
             and city_code = :city_code
             and hotel_code = :hotel_code
          ',
          attributes
        ].first
      end
    end
  end
end

