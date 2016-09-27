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
      def build(hotel)
        result = Roomorama::Property.new(hotel.jtb_hotel_code)
        result.instant_booking!
        result.multi_unit!



        set_base_info!(result, hotel)
        set_description!(result, description)
        set_images!(result, images)
        set_rates_and_minimum_stay!(result, rates)
        set_security_deposit_info!(result, property, security_deposit)

        result
      end

      private

      def set_base_info!(result, hotel)
        result.title = hotel.hotel_name
        result.description = hotel.hotel_description
        result.type = 'apartment'
        result.lat = parse_latitude(hotel.latitude)
        result.lng = parse_longitude(hotel.longitude)
        result.address = hotel.address
        result.postal_code = fetch_postal_code(hotel.address)







        result.city = hotel.city
        result.number_of_bedrooms = hotel.bedrooms
        result.max_guests = hotel.sleeps
        result.default_to_available = false
        result.lat = hotel.xco
        result.lng = hotel.yco
        result.number_of_bathrooms = hotel.bathrooms
        result.number_of_double_beds = calc_double_beds(hotel)
        result.number_of_single_beds = calc_single_beds(hotel)
        result.number_of_sofa_beds = calc_sofa_beds(hotel)
        result.amenities = hotel.amenities
        result.pets_allowed = hotel.pets_allowed
        result.currency = hotel.currency_code
        result.cancellation_policy = CANCELLATION_POLICY

        country_code = country_converter.code_by_name(hotel.country)
        result.country_code = country_code.value if country_code.success?
      end

      def fetch_postal_code(address)
        address.scan(/\d{3}-\d{4}/).first
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

      def fetch_title(property)
        if property.property_name.to_s.empty?
          property.mc_property_name
        else
          property.property_name
        end
      end

      def set_description!(result, description)
        result.description = description
      end

      def calc_double_beds(property)
        property.king_beds + property.queen_beds + property.full_beds
      end

      def calc_single_beds(property)
        property.twin_beds + (property.extra_bed ? 1 : 0)
      end

      def calc_sofa_beds(property)
        property.sofa_bed ? 1 : 0
      end

      def set_images!(result, images)
        images.each do |url|
          identifier = Digest::MD5.hexdigest(url)
          image = Roomorama::Image.new(identifier)
          image.url = url

          result.add_image(image)
        end
      end

      def set_rates_and_minimum_stay!(result, rates)
        min_price = rates.map(&:daily_rate).min

        result.minimum_stay = rates.map(&:min_nights_stay).min
        result.nightly_rate = min_price
        result.weekly_rate  = (min_price * 7).round(2)
        result.monthly_rate = (min_price * 30).round(2)
      end

      def set_security_deposit_info!(result, property, security_deposit)
        amount = extract_security_deposit_amount(security_deposit)
        if amount
          result.security_deposit_currency_code = property.currency_code
          result.security_deposit_amount = amount
          result.security_deposit_type = SECURITY_DEPOSIT_TYPE
        end
      end

      def extract_security_deposit_amount(security_deposit)
        if security_deposit && security_deposit.mandatory && security_deposit.flat_fee && security_deposit.flat_fee_amount != 0
          security_deposit.flat_fee_amount
        end
      end

      def country_converter
        @country_converter ||= Ciirus::CountryCodeConverter.new
      end
    end
  end
end
