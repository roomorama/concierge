module Poplidays
  module Mappers
    # +Poplidays::Mappers::RoomoramaProperty+
    #
    # This class is responsible for building a +Roomorama::Property+ object
    # from data getting from Poplidays API.
    class RoomoramaProperty

      # surface unit information is not included in the response, but surface
      # is always metric
      SURFACE_UNIT = 'metric'

      # currency information is not included in the response, but prices are
      # always quoted in EUR.
      CURRENCY = 'EUR'

      # Maps Poplidays lodging type to Roomorama property type/subtype.
      PROPERTY_TYPES = Concierge::SafeAccessHash.new({
        'APARTMENT' => {type: 'apartment', subtype: 'apartment'},
        'HOUSE'     => {type: 'house', subtype: 'house'},
     })


      # Maps Poplidays API responses to +Roomorama::Property+
      # Arguments
      #
      #   * +property+ [Hash] basic property info
      #   * +details+ [Hash] details property info
      #   * +availabilities+ [Hash] contains 'availabilities' key
      #
      # Returns result wrapped a +Roomorama::Property+
      def build(property, details, availabilities)
        roomorama_property = Roomorama::Property.new(property['id'].to_s)
        roomorama_property.instant_booking!

        set_base_info!(roomorama_property, details)
        set_images!(roomorama_property, details)
        set_amenities!(roomorama_property, details)
        set_rates_and_min_stay!(roomorama_property, details, availabilities)

        Result.new(roomorama_property)
      end

      private

      def set_base_info!(roomorama_property, details)
        roomorama_property.title = details['longLabel']
        roomorama_property.type = PROPERTY_TYPES.get("#{details['type']}.type")
        roomorama_property.subtype = PROPERTY_TYPES.get("#{details['type']}.subtype")
        roomorama_property.address = details['address']['line1']
        roomorama_property.postal_code = details['address']['postalCode']
        roomorama_property.city = details['address']['city']
        roomorama_property.description = build_descriptions(details)
        roomorama_property.number_of_bedrooms = details['bedrooms']
        roomorama_property.max_guests = details['personMax']
        roomorama_property.default_to_available = false
        roomorama_property.country_code = details['country']
        roomorama_property.lat = details['latitude']
        roomorama_property.lng = details['longitude']
        roomorama_property.number_of_bathrooms = details['bathrooms']
        roomorama_property.surface = details['surface']
        roomorama_property.surface_unit = SURFACE_UNIT
        roomorama_property.smoking_allowed = smoking_allowed?(details)
        roomorama_property.pets_allowed = pets_allowed?(details)
        roomorama_property.currency = CURRENCY
      end

      def build_descriptions(details)
        "#{details['description']['indoor']}\n\n#{details['description']['outdoor']}"
      end

      def set_images!(result, details)
        details['photos'].each do |photo|
          image_data = photo['pictures'].max_by { |pic| dimension_to_i(pic['dimension']) }
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
        dimension_str.split('X').reduce(1) { |mul, i| mul * i.to_i }
      end

      def smoking_allowed?(details)
        details['features'].include?('SMOKER')
      end

      def pets_allowed?(details)
        details['features'].include?('PETS')
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

        features = details['features']
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

      def set_rates_and_min_stay!(roomorama_property, details, availabilities_hash)

        availabilities = availabilities_hash['availabilities']

        min_daily_rate = nil
        min_stay = nil
        availabilities.each do |stay|
          next if stay['requestOnly'] && !stay['priceEnabled']

          start_date = Date.parse(stay['arrival'])
          end_date   = Date.parse(stay['departure'])
          length = (end_date - start_date).to_i

          mandatory_services = details['mandatoryServicesPrice']
          subtotal = mandatory_services + stay['price']
          price_per_day = subtotal.to_f / length

          min_daily_rate = [min_daily_rate, price_per_day].compact.min
          min_stay = [min_stay, length].compact.min
        end

        daily_rate = min_daily_rate.round(2)
        roomorama_property.nightly_rate = daily_rate
        roomorama_property.weekly_rate = (daily_rate * 7).round(2)
        roomorama_property.monthly_rate = (daily_rate * 30).round(2)
        roomorama_property.minimum_stay = min_stay
      end
    end
  end
end