module JTB
  module Mappers
    # +JTB::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from JTB.
    class RoomoramaProperty
      CANCELLATION_POLICY = 'super_elite'
      # Until we hear from ciirus on how to determine this field, it will be.. unknown
      SECURITY_DEPOSIT_TYPE = 'unknown'

      IMAGE_URL_PREFIX = 'https://www.jtbgenesis.com/image'

      # Maps JTB data to +Roomorama::Property+
      # Arguments
      #
      #   * +property+ [Ciirus::Entities::Property]
      #   * +images+ [Array] array of images URLs
      #   * +rates+ [Array] array of Ciirus::Entities::PropertyRate
      #   * +description+ [String]
      #   * +security_deposit+ [Ciirus::Entities::Extra] security deposit info
      #                                                  can be nil
      # Returns +Roomorama::Property+
      def build(hotel, pictures, rooms)
        result = Roomorama::Property.new(hotel.jtb_hotel_code)
        result.instant_booking!
        result.multi_unit!
        set_base_info!(result, hotel)
        set_images!(result, pictures)
        set_units!(result, rooms)
        result
      end

      private

      # Each room has several rate plans.
      # Each rate plan has available dates.
      # Returns minimum price for room available dates.
      def fetch_room_min_price(room)
        rate_plans = JTB::Repositories::RatePlanRepository.room_rate_plans(room)
        from = Date.today
        to = from + Workers::Suppliers::JTB::Metadata::PERIOD_SYNC
        stocks = JTB::Repositories::RoomStockRepository.actual_availabilities(rate_plans, from, to)
        stocks.map do |stock|
          JTB::Repositories::RoomPriceRepository.room_min_price(room, rate_plans, stock.service_date)
        end.compact.min
      end

      def set_base_info!(result, hotel)
        result.title = hotel.hotel_name
        result.description = hotel.hotel_description
        result.type = 'apartment'
        result.lat = parse_latitude(hotel.latitude)
        result.lng = parse_longitude(hotel.longitude)
        result.address = hotel.address
        result.postal_code = fetch_postal_code(hotel.address)
        # May be do this in external code
        city = JTB::Repositories::LookupRepository.location_name(hotel.location_code)&.name
        result.city = city
        result.default_to_available = false
        result.currency = JTB::Price::CURRENCY
        result.cancellation_policy = CANCELLATION_POLICY
      end

      def fetch_postal_code(address)
        address&.scan(/\d{3}-\d{4}/)&.first
      end

      def parse_latitude(str)
        str&.gsub(/([NS])(\d+)\.(\d+)\.(.+)/) do
          sign = ($1 == 'N' ? 1 : -1)
          deg = $2.to_i
          min = $3.to_f
          sec = $4.to_f
          sign * (deg + min / 60 + sec / 3600)
        end
      end

      def parse_longitude(str)
        str&.gsub(/([EW])(\d+)\.(\d+)\.(.+)/) do
          sign = ($1 == 'E' ? 1 : -1)
          deg = $2.to_i
          min = $3.to_f
          sec = $4.to_f
          sign * (deg + min / 60 + sec / 3600)
        end
      end

      def set_images!(result, pictures)
        build_images(pictures).each do |image|
          result.add_image(image)
        end
      end

      def build_images(pictures)
        pictures.map do |picture|
          url = [IMAGE_URL_PREFIX, '/', picture.url].join
          identifier = Digest::MD5.hexdigest(url)
          Roomorama::Image.new(identifier).tap do |result|
            image.url = url
            image.caption = picture.comments
            image.position = picture.sequence
          end
        end
      end

      def set_units!(result, rooms)
        rooms.each do |room|
          u_id = JTB::UnitId.from_jtb_codes(room.room_type_code, room.room_code)
          unit = Roomorama::Unit.new(u_id.unit_id)
          unit.title = room.room_name
          unit.max_guests = room.max_guests
          unit.number_of_units = 1

          # Unknown how to handle next room types:
          #  JWS: Japanese and Western Style
          #  DSR: Stateroom
          #  MSN: Maisonette
          unit.number_of_single_beds = fetch_single_beds(room)
          unit.number_of_double_beds = fetch_double_beds(room)
          unit.number_of_sofa_beds = fetch_sofa_beds(room)

          pictures = JTB::Repositories::PictureRepository.room_english_images(room.room_code)
          build_images(pictures).each do |image|
            unit.add_image(image)
          end

          parse_room_amenities!(unit, room)

          unit.minimum_stay = 1
          unit.nightly_rate = fetch_room_min_price(room)

          result.add_unit(unit)
        end
      end




      def fetch_single_beds(room)
        single_beds = case room.room_type_code
                      when 'JPN', 'SGL' then 1
                      when 'TWN' then 2
                      when 'TPL' then 3
                      when 'QUD' then 4
                      end

        extra_single_bed = 1 if has_extra_standart_bed?(room)
        [single_beds, extra_single_bed].compact.inject(:+)
      end

      def fetch_double_beds(room)
        1 if ['DBL', 'SDB', 'SIT'].include?(room.room_type_code)
      end

      def fetch_sofa_beds(room)
        1 if has_extra_sofa_bed?(room)
      end

      def has_extra_standart_bed?(room)
        room.extra_bed == '1' && room.extra_bed_type == '1'
      end

      def has_extra_sofa_bed?(room)
        room.extra_bed == '1' && room.extra_bed_type == '3'
      end

      def parse_room_amenities!(unit, room)
        amenities = []
        room_amenities = room.amenities.chars
        room_amenities.each_with_index do |available, index|
          room_amenity = JTB::Repositories::LookupRepository.room_amenity(amenity_id(index + 1))
          next unless room_amenity
          mapping = lookup_amenities(room_amenity.name)
          amenities << mapping if available == '1' && mapping

          if non_smoking_room_amenity?(room_amenity.name)
            unit.smoking_allowed = case available
                                   when '1' then false
                                   when '0' then true
                                   end
          end
        end

        unit.amenities = amenities
      end

      def fetch_unit_amenities(room)
        result = []
        amenities = room.amenities.chars
        amenities.each_with_index do |available, index|
          amenity = JTB::Repositories::LookupRepository.room_amenity(amenity_id(index + 1))
          next unless amenity
          mapping = lookup_amenities(amenity.name)
          result << mapping if (available == '1' && mapping)
        end

        result
      end

      # Convert integer to amenity index.
      # Amenity index is string with length 3 with leading zeros.
      #
      #   amenity_id(2) => "002"
      def amenity_id(index)
        '%03d' % index
      end

      def non_smoking_room_amenity?(amenity_name)
        amenity_name == 'Non-smoking'
      end

      def lookup_amenities(name)
        case name
        when 'Air conditioning', 'Air conditioning for free', 'Air conditioning to charge'
          :airconditioning
        when 'Balcony (porch)'
          :balcony
        when 'Bath towel', 'Hand towel',  'Towel'
          :bed_linen_and_towels
        when 'Breakfast at in-house theater', 'Breakfast at irori fire place', 'Breakfast at restaurant',
          'Breakfast buffet', 'Breakfast in banquet hall', 'Breakfast in the private dining room', 'In-room breakfast'
          :breakfast
        when 'DVD player', 'Pay TV', 'Pay TV (check-out payment)', 'Pay TV (prepaid card)', 'TV', 'TV for free', 'TV to charge', 'VCR'
          :tv
        when 'Forest', 'Garden', 'Lake', 'Mountain', 'Open-air bath', 'Open-air bath w/ heated water',
          'Open-air bath w/ hot spring water', 'River', 'Rural district', 'Sea', 'Valley', 'Waterfall'
          :outdoor_space
        when 'Internet'
          :internet
        when 'Wheelchair (doorway over 80cm)'
          :wheelchairaccess
        end
      end
    end
  end
end
