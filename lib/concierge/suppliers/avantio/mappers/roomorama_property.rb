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
        set_amenities!(result, accommodation)
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
        result.neighborhood = accommodation.district
        result.country_code = accommodation.country_iso_code
        result.lat = accommodation.lat
        result.lng = accommodation.lng
        result.default_to_available = false
        result.number_of_bathrooms = fetch_bathrooms(accommodation)
        result.floor = accommodation.floor
        result.number_of_double_beds = accommodation.double_beds
        result.number_of_single_beds = accommodation.individual_beds # use berths?
        result.number_of_sofa_beds = fetch_sofa_beds(accommodation)
        result.surface = accommodation.housing_area
        result.surface_unit = fetch_surface_unit(accommodation)
        result.pets_allowed = accommodation.pets_allowed
        result.currency = accommodation.currency
        result.cancellation_policy = CANCELLATION_POLICY
      end

      def fetch_surface_unit(accommodation)
        if accommodation.housing_area
          accommodation.area_unit == 'm' ? 'metric' : 'imperial'
        end
      end

      def fetch_sofa_beds(accommodation)
        [
          accommodation.individual_sofa_beds,
          accommodation.double_sofa_beds
        ].compact.inject(:+)
      end

      def fetch_bathrooms(accommodation)
        [
          accommodation.bathtub_bathrooms,
          accommodation.shower_bathrooms
        ].compact.inject(:+)
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

      def set_amenities!(result, accommodation)
        amenities = []
        # amenities << 'bed_linen_and_towels'
        amenities << 'kitchen' if accommodation.number_of_kitchens.to_i > 0
        # amenities << 'wifi' # from accommodation
        # amenities << 'internet' # from accommodation
        amenities << 'tv' if accommodation.tv || accommodation.dvd
        # amenities << 'parking' # from accommodation
        # amenities << 'airconditioning' # from accommodation
        amenities << 'laundry' if accommodation.washing_machine
        amenities << 'free_cleaning' if accommodation.free_cleaning
        amenities << 'wheelchairaccess' if suitable_for_disabled?(accommodation)
        amenities << 'pool' if pool?(accommodation)
        amenities << 'gym' if accommodation.gym
        # amenities << 'breakfast'
        amenities << 'elevator' if accommodation.elevator
        amenities << 'balcony' if accommodation.balcony
        amenities << 'outdoor_space' if outdoor_space?(accommodation)
      end

      def pool?(accommodation)
        !['', 'ninguna'].include?(accommodation.pool_type) ||
          accommodation.pool_service
      end

      def suitable_for_disabled?(accommodation)
        # suitable for disabled, without-stairs
        ['apta-discapacitados',
         'sin-escaleras'].include?(accommodation.handicapped_facilities)
      end

      def outdoor_space?(accommodation)
        accommodation.fire_place ||
          accommodation.garden ||
          accommodation.bbq ||
          accommodation.terrace ||
          accommodation.fenced_plot
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
