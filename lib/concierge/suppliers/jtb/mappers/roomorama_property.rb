module JTB
  module Mappers
    # +JTB::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from JTB.
    class RoomoramaProperty
      CANCELLATION_POLICY = 'super_elite'
      IMAGE_URL_PREFIX = 'https://www.jtbgenesis.com/image'
      PROPERTY_TYPE = 'apartment'
      COUNTRY_CODE = 'JP'

      ROOM_TYPE_CODES = {
        'SGL' => 'Single',
        'SDB' => 'Semi-double',
        'TWN' => 'Twin',
        'DBL' => 'Double',
        'TPL' => 'Triple',
        'QUD' => 'Quad',
        'SIT' => 'Suite',
        'JPN' => 'Japanese-style',
        'JWS' => 'Japanese and Western Style',
        'DSR' => 'Stateroom',
        'MSN' => 'Maisonette'
      }

      # Maps JTB data to +Roomorama::Property+
      # Arguments
      #
      #   * +hotel+ [JTB::Entities::Hotel]
      # Returns +Roomorama::Property+
      def build(hotel)
        property = Roomorama::Property.new(hotel.jtb_hotel_code)
        property.instant_booking!
        property.multi_unit!

        set_base_info!(property, hotel)
        set_images!(property, hotel)
        set_units!(property, hotel)
        set_rates!(property)

        error = validate(property)
        return error if error

        Result.new(property)
      end

      private

      def set_rates!(property)
        min_nightly_rate = property.units.map(&:nightly_rate).compact.min
        if min_nightly_rate
          property.nightly_rate = min_nightly_rate.to_f
          property.weekly_rate = 7 * property.nightly_rate
          property.monthly_rate = 30 * property.nightly_rate
        end
      end

      def validate(property)
        if property.empty_images?
          return Result.error(:empty_images, 'Property images list is empty')
        end
        unless property.nightly_rate
          return Result.error(:unknown_nightly_rate, 'No one of property units has prices information')
        end
      end

      # Each room has several rate plans.
      # Each rate plan has available dates.
      # Returns minimum price for room available dates.
      def fetch_room_min_price(room)
        rate_plans = JTB::Repositories::RatePlanRepository.room_rate_plans(room)
        from = Date.today
        to = from + Workers::Suppliers::JTB::Metadata::PERIOD_SYNC
        JTB::Repositories::RoomPriceRepository.room_min_price(rate_plans, from, to)
      end

      def set_base_info!(result, hotel)
        result.title = hotel.hotel_name
        result.description = hotel.hotel_description
        result.type = PROPERTY_TYPE
        result.lat = parse_latitude(hotel.latitude)
        result.lng = parse_longitude(hotel.longitude)
        result.address = hotel.address
        result.postal_code = fetch_postal_code(hotel.address)
        # May be do this in external code
        city = JTB::Repositories::LookupRepository.location_name(hotel.location_code)&.name
        result.city = prepare_city(city) if city
        result.default_to_available = false
        result.minimum_stay = 1
        result.currency = JTB::Price::CURRENCY
        result.cancellation_policy = CANCELLATION_POLICY
        result.country_code = COUNTRY_CODE
        result.check_in_time = prepare_time(hotel.check_in)
        result.check_out_time = prepare_time(hotel.check_out)
      end

      # convert JTB time format
      # "1130" => "11:30"
      def prepare_time(time)
        if time
          h = time[0..1]
          m = time[2..3]
          [h, m].join(':')
        end
      end

      # JTB location names are often complex and
      # this method simplifies them.
      #
      # prepare_city('Tokyo (TokyoStation / Kanda / Kudan)') => "Tokyo"
      # prepare_city('Kanagawa (Yokohama / Odawara)') => "Kanagawa"
      # prepare_city('Tokyo (TokyoStation / Kanda / Kudan)') => "Tokyo"

      def prepare_city(city)
        index = city.index('(')

        return city unless index

        city[0..(index - 1)].strip
      end

      def fetch_postal_code(address)
        address&.scan(/\d{3}-\d{4}/)&.first
      end

      def parse_latitude(str)
        result = str&.gsub(/([NS])(\d+)\.(\d+)\.(.+)/) do
          sign = ($1 == 'N' ? 1 : -1)
          deg = $2.to_i
          min = $3.to_f
          sec = $4.to_f
          sign * (deg + min / 60 + sec / 3600)
        end

        result if result != str
      end

      def parse_longitude(str)
        result = str&.gsub(/([EW])(\d+)\.(\d+)\.(.+)/) do
          sign = ($1 == 'E' ? 1 : -1)
          deg = $2.to_i
          min = $3.to_f
          sec = $4.to_f
          sign * (deg + min / 60 + sec / 3600)
        end

        result if result != str
      end

      def set_images!(result, hotel)
        pictures = JTB::Repositories::PictureRepository.hotel_english_images(hotel.city_code, hotel.hotel_code)

        build_images(pictures).each do |image|
          result.add_image(image)
        end
      end

      def build_images(pictures)
        pictures.map do |picture|
          url = [IMAGE_URL_PREFIX, '/', picture.url].join
          identifier = Digest::MD5.hexdigest(url)
          Roomorama::Image.new(identifier).tap do |result|
            result.url = url
            result.caption = picture.comments
            result.position = picture.sequence
          end
        end
      end

      def set_units!(result, hotel)
        rooms = JTB::Repositories::RoomTypeRepository.hotel_english_rooms(hotel.city_code, hotel.hotel_code)

        rooms.each do |room|
          u_id = JTB::UnitId.from_jtb_codes(room.room_type_code, room.room_code)
          unit = Roomorama::Unit.new(u_id.unit_id)
          unit.title = room.room_name
          unit.description = build_description(room)
          unit.max_guests = room.max_guests
          unit.number_of_units = 1
          unit.number_of_bedrooms = 1

          # Unknown how to handle next room types:
          #  JWS: Japanese and Western Style
          #  DSR: Stateroom
          #  MSN: Maisonette
          unit.number_of_single_beds = fetch_single_beds(room)
          unit.number_of_double_beds = fetch_double_beds(room)
          unit.number_of_sofa_beds = fetch_sofa_beds(room)

          set_unit_surface!(unit, room)

          pictures = JTB::Repositories::PictureRepository.room_english_images(room.room_code)
          build_images(pictures).each do |image|
            unit.add_image(image)
          end

          parse_room_amenities!(unit, room)

          unit.minimum_stay = 1
          unit.nightly_rate = fetch_room_min_price(room)
          if unit.nightly_rate
            unit.weekly_rate = 7 * unit.nightly_rate
            unit.monthly_rate = 30 * unit.nightly_rate
          end

          result.add_unit(unit)
        end
      end

      def set_unit_surface!(unit, room)
        if room.size1
          # Room Size (Western Type)
          unit.surface = room.size1.to_f
          unit.surface_unit = 'metric'
        elsif room.size6
          # Room Size of Western Stype Room
          unit.surface = room.size6.to_f
          unit.surface_unit = 'metric'
        elsif room.size2
          # Room Size of Main Room
          # Room Size of Room Entrance
          # Room Size of Anteroom
          unit.surface = room.size2.to_f + room.size3.to_f + room.size4.to_f
          unit.surface_unit = 'tatami mat'
        elsif room.size5
          # Room Size of Japanese Stype Room
          unit.surface = room.size5.to_f
          unit.surface_unit = 'tatami mat'
        end
      end

      def build_description(room)
        # Didn't see rooms with nil room_grade and room_type_code at the same time.
        descriptions = []
        if room.room_grade
          name = JTB::Repositories::LookupRepository.room_grade(room.room_grade).name
          descriptions << "Room Grade: #{name}."
        end

        if room.room_type_code
          name = ROOM_TYPE_CODES[room.room_type_code]
          descriptions << "Room Type: #{name}."
        end

        descriptions.join(' ')
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
        amenities = Set.new
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

        unit.amenities = amenities.to_a
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
