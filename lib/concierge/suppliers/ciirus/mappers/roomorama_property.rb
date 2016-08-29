module Ciirus
  module Mappers
    # +Ciirus::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from Ciirus API.
    class RoomoramaProperty
      CANCELLATION_POLICY = 'super_elite'
      # Until we hear from ciirus on how to determine this field, it will be.. unknown
      SECURITY_DEPOSIT_TYPE = 'unknown'

      # Maps Ciirus PropertyType to Roomorama property type/subtype.
      # There are also `Unspecified` and `Hotel` types in Ciirus API
      # but roomorama doesn't support them.
      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        'Condo'           => {type: 'apartment', subtype: 'condo'},
        'Townhouse'       => {type: 'house'},
        'Apartment'       => {type: 'apartment'},
        'Villa'           => {type: 'house', subtype: 'villa'},
        'Signature Villa' => {type: 'house', subtype: 'villa'},
        'House'           => {type: 'house'},
        'Cottage'         => {type: 'house', subtype: 'cottage'},
        'B+B'             => {type: 'bnb'},
        'Cabin'           => {type: 'house', subtype: 'cabin'},
        'Motel'           => {type: 'room'},
        'Studio'          => {type: 'apartment', subtype: 'studio_bachelor'},
        'Resort Home'     => {type: 'house'},
        'Private Room'    => {type: 'room'},
        'Finca'           => {type: 'house'}
      })


      # Maps Ciirus API responses to +Roomorama::Property+
      # Arguments
      #
      #   * +property+ [Ciirus::Entities::Property]
      #   * +images+ [Array] array of images URLs
      #   * +rates+ [Array] array of Ciirus::Entities::PropertyRate
      #   * +description+ [String]
      #   * +security_deposit+ [Ciirus::Entities::Extra] security deposit info
      #                                                  can be nil
      # Returns +Roomorama::Property+
      def build(property, images, rates, description, security_deposit)
        result = Roomorama::Property.new(property.property_id)
        result.instant_booking!

        set_base_info!(result, property)
        set_description!(result, description)
        set_images!(result, images)
        set_rates_and_minimum_stay!(result, rates)
        set_security_deposit_info!(result, property, security_deposit)

        result
      end

      private

      def set_base_info!(result, property)
        result.title = fetch_title(property)
        result.type = PROPERTY_TYPES.get("#{property.type}.type")
        result.subtype = PROPERTY_TYPES.get("#{property.type}.subtype")
        result.address = property.address
        result.postal_code = property.zip
        result.city = property.city
        result.number_of_bedrooms = property.bedrooms
        result.max_guests = property.sleeps
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
