module Avantio
  module Mappers
    # +Avantio::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from Avantio.
    class RoomoramaProperty
      CANCELLATION_POLICY = 'super_elite'
      # Until we hear from Avantio on how to determine this field, it will be.. unknown
      SECURITY_DEPOSIT_TYPE = 'unknown'

      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        1  => {type: 'apartment'}, # Apartment
        4  => {type: 'apartment'}, # Aparthotel
        2  => {type: 'house', subtype: 'villa'}, # Villa
        14 => {type: 'apartment', subtype: 'studio_bachelor'}, # Studio
        20 => {type: 'house', subtype: 'cottage'}, # Chalet
        9  => {type: 'house', subtype: 'cottage'}, # Cottage
        21 => {type: 'house', subtype: 'bungalow'} # Bungalow
      })

      # Maps Avantio data to +Roomorama::Property+
      # Arguments
      #
      #   * +accommodation+ [Avantio::Entities::Accommodation]
      # Returns +Roomorama::Property+
      def build(accommodation)
        result = Roomorama::Property.new(accommodation.property_id)
        result.instant_booking!

        set_base_info!(result, accommodation)
        set_description!(result, description)
        set_images!(result, images)
        set_rates_and_minimum_stay!(result, rates)
        set_security_deposit_info!(result, property, security_deposit)

        result
      end

      private

      def set_base_info!(result, accommodation)
        result.title = accommodation.accommodation_name
        result.type = PROPERTY_TYPES.get("#{accommodation.master_kind_code}.type")
        result.subtype = PROPERTY_TYPES.get("#{accommodation.master_kind_code}.subtype")
        result.address = fetch_address(accommodation)
        result.postal_code = accommodation.postal_code
        result.city = fetch_city(accommodation)
        result.number_of_bedrooms = accommodation.bedrooms
        result.max_guests = accommodation.people_capacity
        result.apartment_number = accommodation.door



        result.default_to_available = false
        result.lat = property.xco
        result.lng = property.yco
        result.number_of_bathrooms = property.bathrooms
        result.number_of_double_beds = calc_double_beds(property)
        result.number_of_single_beds = calc_single_beds(property)
        result.number_of_sofa_beds = calc_sofa_beds(property)
        result.amenities = property.amenities
        result.pets_allowed = property.pets_allowed
        result.currency = property.currency_code
        result.cancellation_policy = CANCELLATION_POLICY

        country_code = country_converter.code_by_name(property.country)
        result.country_code = country_code.value if country_code.success?
      end

      def fetch_address(accommodation)
        [
          accommodation.street,
          accommodation.number,
          accommodation.block
        ].select { |x| !x.to_s.empty? }.join(', ') unless accommodation.street.to_s.empty?
      end

      # some city names contain multiple versions of the city name separated by
      # a slash ("Gerona / Girona"). This is confusing geolocalization of the property
      # on Roomorama. We just pick the first option in case this happens.
      def fetch_city(accommodation)
        accommodation.city&.split('/')&.first&.strip
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
