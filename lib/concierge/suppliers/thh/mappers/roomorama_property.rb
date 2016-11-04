module THH
  module Mappers
    # +THH::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from THH API.
    class RoomoramaProperty
      SYNC_PERIOD = 365
      SECURITY_DEPOSIT_TYPE = 'cash'
      SECURITY_DEPOSIT_CURRENCY = 'THB'
      CANCELLATION_POLICY = 'strict'

      # Maps THH type to Roomorama property type/subtype.
      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        'Villa'     => {type: 'house', subtype: 'villa'},
        'Apartment' => {type: 'apartment'},
      })

      # Maps THH API raw property to +Roomorama::Property+
      # Arguments
      #
      #  * +raw_property+ [Hash] property from +data_all+ response
      #
      # Returns +Roomorama::Property+
      def build(raw_property)
        property = Roomorama::Property.new(raw_property['property_id'])
        property.instant_booking!

        set_base_info!(property, raw_property)
        set_images!(property, raw_property)
        set_amenities!(property, raw_property)
        set_rates_and_min_stay!(property, raw_property)
        set_security_deposit!(property, raw_property)

        property
      end

      private

      def set_base_info!(property, raw_property)
        property.default_to_available = false
        property.title = raw_property['property_name']
        property.type = PROPERTY_TYPES.get("#{raw_property['type']}.type")
        property.subtype = PROPERTY_TYPES.get("#{raw_property['type']}.subtype")
        property.country_code = country_converter.code_by_name(raw_property['country'])
        property.city = raw_property['city']
        property.neighborhood = raw_property['region']
        property.description = build_description(raw_property)
        property.number_of_bedrooms = raw_property['bedrooms']
        property.max_guests = raw_property['pax']
        property.lat = raw_property.get('geodata.lat')
        property.lng = raw_property.get('geodata.lng')
        property.number_of_bathrooms = raw_property.get('bathrooms')
        property.number_of_double_beds = raw_property.get('beds.double_beds')
        property.number_of_single_beds = raw_property.get('beds.single_beds')
        property.number_of_sofa_beds = raw_property.get('beds.sofa_beds')
        property.cancellation_policy = CANCELLATION_POLICY
      end

      def set_amenities!(property, raw_property)
        attributes = raw_property['attributes']

        amenities = []

        if attributes
          amenities << 'kitchen' if has_kitchen?(attributes)
          amenities << 'wifi' if attributes.get('amenities.wifi')
          amenities << 'cabletv' if attributes.get('equipment.living_room.cable_tv')
          amenities << 'parking' if attributes.get('outside.parking')
          amenities << 'airconditioning' if attributes.get('amenitites.air_conditioning')
          amenities << 'laundry' if has_laundry?(attributes)
          amenities << 'pool' if has_pool?(attributes)
          amenities << 'balcony' if attributes.get('outside.balcony')
          amenities << 'outdoor_space' if has_outdoor_space?(attributes)
          amenities << 'gym' if attributes.get('amenities.gym')
          amenities << 'bed_linen_and_towels' if has_linen_and_towels?(attributes)
        end

        property.amenities = amenities
      end

      def has_linen_and_towels?(attributes)
        attributes.get('amenities.linen_provided') &&
          attributes.get('amenities.towels_provided')
      end

      def has_outdoor_space?(attributes)
        attributes.get('outside.bbq') ||
          attributes.get('outside.private_garden') ||
          attributes.get('outside.private_lake')
      end

      def has_laundry?(attributes)
        attributes.get('equipment.other.washing_machine') ||
          attributes.get('equipment.other.clothes_dryer')
      end

      def has_kitchen?(attributes)
        kitchen = attributes.get('equipment.kitchen')
        # Possible values in kitchen: cooker, fridge, freezer, microwave,
        # toaster, oven, hob, kettle, dishwasher
        kitchen && kitchen.to_h.length > 1
      end

      def has_pool?(attributes)
        attributes.get('pool.communal_pool') ||
          attributes.get('pool.private_pool')
      end

      def set_rates_and_min_stay!(property, raw_property)
        rates = Array(raw_property.get('rates.rate'))
        booked_periods = Array(raw_property.get('calendar.periods.period'))

        calendar = THH::Calendar.new(rates, booked_periods, SYNC_PERIOD)

        property.minimum_stay = calendar.min_stay
        property.nightly_rate = calendar.min_rate
        if property.nightly_rate
          property.weekly_rate = property.nightly_rate * 7
          property.monthly_rate = property.nightly_rate * 30
          property.currency = THH::Commands::PropertiesFetcher::CURRENCY
        end
      end

      def set_images!(property, raw_property)
        urls = Array(raw_property.get('pictures.picture'))

        main_picture = raw_property.get('pictures.picture_main')
        urls << main_picture if main_picture

        urls.each do |url|
          identifier = Digest::MD5.hexdigest(url)
          image = Roomorama::Image.new(identifier)
          image.url = url
          property.add_image(image)
        end
      end

      def build_description(raw_property)
        [
          raw_property.get('descriptions.description_short.brief'),
          raw_property.get('descriptions.description_full.text'),
          raw_property.get('descriptions.rooms.living_area'),
          raw_property.get('descriptions.rooms.kitchen'),
          raw_property.get('descriptions.rooms.dining_room'),
          raw_property.get('descriptions.rooms.bedrooms'),
          raw_property.get('descriptions.rooms.bathrooms'),
          raw_property.get('descriptions.rooms.utility_room'),
          raw_property.get('descriptions.rooms.other'),
          raw_property.get('descriptions.rooms.cleaning'),
        ].compact.join("\n\n")
      end

      def set_security_deposit!(property, raw_property)
        value = raw_property.get('additional_information.deposit')
        if value
          property.security_deposit_amount = rate_to_f(value)
          property.security_deposit_type = SECURITY_DEPOSIT_TYPE
          property.security_deposit_currency_code = SECURITY_DEPOSIT_CURRENCY
        end
      end

      def rate_to_f(rate)
        rate.gsub(/[,\s]/, '').to_f
      end

      def country_converter
        THH::CountryCodeConverter.new
      end
    end
  end
end