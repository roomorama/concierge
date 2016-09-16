module Poplidays
  module Mappers
    # +Poplidays::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from Poplidays API.
    class RoomoramaProperty
      # NOTE: actually Poplidays API doesn't support cancellation
      CANCELLATION_POLICY = 'super_elite'

      # Apparently Poplidays does not have the "security deposit method",
      # and they ask the guest to figure out directly with the host.
      # Use "unknown" deposit type
      SECURITY_DEPOSIT_TYPE = 'unknown'

      # surface unit information is not included in the response, but surface
      # is always metric
      SURFACE_UNIT = 'metric'

      # When the local agent does not indicate the amount of the deposit,
      # Poplidays, indicates that studio is around 300 € and villas can be up to 1000€.
      SECURITY_DEPOSIT_AMOUNT = {
        'APARTMENT' => 300.0,
        'HOUSE'     => 1000.0
      }

      # currency information is not included in the response, but prices are
      # always quoted in EUR.
      CURRENCY = 'EUR'

      # Maps Poplidays lodging type to Roomorama property type/subtype.
      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        'APARTMENT' => {type: 'apartment'},
        'HOUSE'     => {type: 'house'},
     })


      # Maps Poplidays API responses to +Roomorama::Property+
      # Arguments
      #
      #   * +property+ [Hash] basic property info
      #   * +details+ [SafeAccessHash] details property info
      #   * +availabilities+ [Array] availabilities
      #   * +extras+ [Array] array of extra Hashes, can be nil
      #
      # Returns result wrapped a +Roomorama::Property+
      def build(property, details, availabilities, extras)
        roomorama_property = Roomorama::Property.new(property['id'].to_s)
        roomorama_property.instant_booking!

        set_base_info!(roomorama_property, details)
        set_images!(roomorama_property, details)
        set_amenities!(roomorama_property, details)
        set_rates_and_min_stay!(roomorama_property, details, availabilities)
        set_security_deposit!(roomorama_property, details)
        set_cleaning_info!(roomorama_property, extras)

        Result.new(roomorama_property)
      end

      private

      def set_base_info!(roomorama_property, details)
        roomorama_property.title = details['longLabel']
        roomorama_property.type = PROPERTY_TYPES.get("#{details['type']}.type")
        roomorama_property.subtype = PROPERTY_TYPES.get("#{details['type']}.subtype")
        roomorama_property.address = details.get('address.line1')
        roomorama_property.postal_code = details.get('address.postalCode')
        roomorama_property.city = details.get('address.city')
        roomorama_property.description = build_descriptions(details)
        roomorama_property.number_of_bedrooms = details['bedrooms']
        roomorama_property.max_guests = details['personMax']
        roomorama_property.default_to_available = false
        roomorama_property.country_code = details['country']
        roomorama_property.lat = details['latitude']
        roomorama_property.lng = details['longitude']
        roomorama_property.number_of_bathrooms = details['bathrooms']
        roomorama_property.smoking_allowed = smoking_allowed?(details)
        roomorama_property.pets_allowed = pets_allowed?(details)
        roomorama_property.currency =  CURRENCY
        roomorama_property.cancellation_policy = CANCELLATION_POLICY

        # Some properties have 0 value
        if details['surface'].to_i != 0
          roomorama_property.surface = details['surface']
          roomorama_property.surface_unit = SURFACE_UNIT
        end
      end

      def set_security_deposit!(roomorama_property, details)
        roomorama_property.security_deposit_currency_code = CURRENCY
        roomorama_property.security_deposit_type = SECURITY_DEPOSIT_TYPE
        if details['caution'] == 'unknown'
          roomorama_property.security_deposit_amount = SECURITY_DEPOSIT_AMOUNT[details['type']]
        else
          roomorama_property.security_deposit_amount = details['caution'].to_f
        end
      end

      def build_descriptions(details)
        [details.get('description.indoor'), details.get('description.outdoor')].compact.join("\n\n")
      end

      def set_images!(result, details)
        Array(details['photos']).each do |photo|
          image_data = Array(photo['pictures']).max_by { |pic| dimension_to_i(pic['dimension'].to_s) }
          if image_data
            url = image_data['url']
            identifier = Digest::MD5.hexdigest(url)
            image = Roomorama::Image.new(identifier)
            image.url = url
            result.add_image(image)
          end
        end
      end

      def dimension_to_i(dimension_str)
        dimension_str.split('X').map(&:to_i).inject(1, :*)
      end

      def smoking_allowed?(details)
        Array(details['features']).include?('SMOKER')
      end

      def pets_allowed?(details)
        Array(details['features']).include?('PETS')
      end

      # Currently known Poplidays property features are
      # ["PETS", "LIFT", "BATH", "AIRCONDITIONING", "OVEN",
      # "WASHINGMACHINE", "DISHWASHER", "MICROWAVE", "GARDENFURNITURE",
      # "GROUPPOOL", "PARKING", "TELEVISION", "TERRACE", "BARBECUE",
      # "HEATING", "SMOKER", "GARDEN", "FIREPLACE", "FREEZER", "COT",
      # "TUMBLEDRYER", "SHOWER", "INTERNET", "BALCONY", "HANDICAPEDACCESS",
      # "SEPARATETOILET", "GREENAREA", "PRIVATEPOOL", "SMALLOVEN", "SAUNA",
      # "BILLIARDTABLE", "JACUZZI", "TENNIS"]
      def set_amenities!(roomorama_property, details)
        amenities = []

        features = Array(details['features'])
        amenities << 'kitchen' if has_kitchen?(features)
        amenities << 'internet' if features.include?('INTERNET')
        amenities << 'tv' if features.include?('TELEVISION')
        amenities << 'parking' if features.include?('PARKING')
        amenities << 'airconditioning' if features.include?('AIRCONDITIONING')
        amenities << 'laundry' if features.include?('WASHINGMACHINE')
        amenities << 'wheelchairaccess' if features.include?('HANDICAPEDACCESS')
        amenities << 'pool' if has_pool?(features)
        amenities << 'elevator' if features.include?('LIFT')
        amenities << 'balcony' if features.include?('BALCONY')
        amenities << 'outdoor_space' if has_outdoor_space?(features)

        roomorama_property.amenities = amenities
      end

      def has_pool?(features)
        features.include?('GROUPPOOL') ||
          features.include?('PRIVATEPOOL')
      end

      def has_outdoor_space?(features)
        features.include?('GARDENFURNITURE') ||
          features.include?('TERRACE') ||
          features.include?('BARBECUE') ||
          features.include?('GARDEN') ||
          features.include?('FIREPLACE') ||
          features.include?('GREENAREA')
      end

      def has_kitchen?(features)
        features.include?('OVEN') ||
          features.include?('DISHWASHER') ||
          features.include?('MICROWAVE') ||
          features.include?('SMALLOVEN') ||
          features.include?('FREEZER')
      end

      def set_rates_and_min_stay!(roomorama_property, details, availabilities)
        mandatory_services = details['mandatoryServicesPrice'].to_f
        stays = availabilities.map { |a| to_stay(a, mandatory_services) }
        min_stay = stays.map(&:length).min
        daily_rate = stays.map(&:rate).min

        roomorama_property.nightly_rate = daily_rate
        roomorama_property.weekly_rate = (daily_rate * 7).round(2)
        roomorama_property.monthly_rate = (daily_rate * 30).round(2)
        roomorama_property.minimum_stay = min_stay
      end

      def set_cleaning_info!(roomorama_property, extras)
        if extras
          cleaning_extra = find_cleaning_extra(Array(extras['extras']))
          return unless cleaning_extra

          if cleaning_extra['mandatory']
            # Cleaning fee already included in booking price
            roomorama_property.services_cleaning = false
          else
            roomorama_property.services_cleaning = true
            roomorama_property.services_cleaning_required = false
            roomorama_property.services_cleaning_rate = cleaning_extra['_price']
          end
        end
      end

      # Finds cleaning extra among others.
      # If cleaning depends on other services returns nil
      def find_cleaning_extra(extras)
        cleaning_extra = extras.detect { |e| e['code'] == 'CLEANING_DURING_THE_STAY' }
        return unless cleaning_extra

        price = calc_cleaning_extra_price(cleaning_extra)
        return unless price

        cleaning_extra['_price'] = price
        cleaning_extra
      end

      # An extra is selectable by user and sometimes its price depends on others extras.
      # That's why, an extra has more than one price.
      # But we need info only about cleaning extra (without others)
      def calc_cleaning_extra_price(cleaning_extra)
        prices = Array(cleaning_extra['prices'])
        price = prices.detect { |p| p['selectedCodes'].nil? }
        price['value'] if price
      end

      def to_stay(availability, mandatory_services)
        Roomorama::Calendar::Stay.new(
          {
            checkin: availability['arrival'],
            checkout: availability['departure'],
            price: mandatory_services + availability['price']
          }
        )
      end
    end
  end
end
