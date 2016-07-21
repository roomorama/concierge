module Kigo::Mappers
  # +Kigo::Mappers::Property+
  #
  # This class responsible for setting data and performing data to Roomorama format
  #
  # ==== Attributes
  #
  # * +property+   - +Roomorama::Property+ instance
  # * +payload+    - hash based Kigo payload
  # * +references+ - list of references data
  #
  class Property
    CANCELLATION_POLICY = 'super_elite'

    attr_reader :property, :payload, :references

    def initialize(references)
      @references = references
    end

    # manages data and returns the result with +Roomorama::Property+
    def prepare(property_data)
      build_room(property_data)
      property.instant_booking!

      set_base_info
      set_description
      set_beds_count
      set_amenities
      # set_deposit
      # set_cleaning_service
      # set_property_type
      # set_images
      # set_price_and_availabilities
      #
      Result.new(property)
    end

    private

    def build_room(property_data)
      @payload  = Concierge::SafeAccessHash.new(property_data)
      @property = Roomorama::Property.new(property_data['PROP_ID'].to_s)
    end

    def info
      payload['PROP_INFO']
    end

    def set_base_info
      property.title                = info['PROP_NAME']
      property.number_of_bedrooms   = info['PROP_BEDROOMS']
      property.number_of_bathrooms  = info['PROP_BATHROOMS']
      property.surface              = info['PROP_SIZE']
      property.surface_unit         = surface_unit(info['PROP_SIZE_UNIT'])
      property.max_guests           = info['PROP_MAXGUESTS']
      property.pets_allowed         = amenity_ids.include?(code_for(:pets_allowed))
      property.smoking_allowed      = amenity_ids.include?(code_for(:smoking_allowed))
      property.cancellation_policy  = CANCELLATION_POLICY
      property.default_to_available = true

      property.country_code     = info['PROP_COUNTRY']
      property.city             = info['PROP_CITY']
      property.neighborhood     = info['PROP_REGION']
      property.postal_code      = info['PROP_POSTCODE']
      property.address   = street_address
      property.apartment_number = info['PROP_APTNO']
      coordinates               = info['PROP_LATLNG']
      property.lat              = coordinates['LATITUDE']
      property.lng              = coordinates['LONGITUDE']
    end

    def set_description
      description = info['PROP_DESCRIPTION']
      description = info['PROP_SHORTDESCRIPTION'] if description.strip.empty?
      description = info['PROP_AREADESCRIPTION'] if description.strip.empty?

      property.description = description
    end

    def surface_unit(name)
      name == 'SQFEET' ? 'imperial' : 'metric'
    end

    def street_address
      addresses = [info['PROP_STREETNO'], info['PROP_ADDR1'], info['PROP_ADDR2'], info['PROP_ADDR3']].reject(&:empty?)
      addresses.join(', ')
    end

    # payload presents beds size as different named items
    def set_beds_count
      mapper = Beds.new(info['PROP_BED_TYPES'])

      property.number_of_double_beds = mapper.double_beds.size
      property.number_of_single_beds = mapper.single_beds.size
      property.number_of_sofa_beds   = mapper.sofa_beds.size
    end

    def set_amenities
      property.amenities = amenities_mapper.map(amenity_ids)
    end

    def amenities_mapper
      Amenities.new(references[:amenities])
    end

    def set_deposit
      deposit = find_cost('Deposit')
      return unless deposit

      if deposit['Payment'] == 'MandatoryDepositOnSite'
        property.security_deposit_amount        = deposit['Amount'].to_i
        property.security_deposit_type          = 'cash'
        property.security_deposit_currency_code = Price::CURRENCY
      end
    end

    def set_cleaning_service
      cleaning = find_cost('Cleaning')
      return unless cleaning

      property.services_cleaning          = cleaning['Payment'] != 'None'
      property.services_cleaning_required = cleaning['Payment'] == 'Mandatory'
      property.services_cleaning_rate     = cleaning['Amount']

      property.amenities << 'free_cleaning' if cleaning['Payment'] == 'Inclusive'
    end


    # sets type and subtype accordingly related code
    def set_property_type
      properties_array = payload['PropertiesV1']
      room_type_hash   = properties_array.find { |data_hash| data_hash['TypeNumber'] == code_for(:property_type) }
      room_type_number = room_type_hash['TypeContents'].first

      case room_type_number
      when 20 # Castle
        property.type    = 'house'
        property.subtype = 'chateau'
      when 30 # Cottage
        property.type    = 'house'
        property.subtype = 'cottage'
      when 40 # Mansion
        property.type    = 'house'
        property.subtype = 'townhouse'
      when 50 # Villa
        property.type    = 'house'
        property.subtype = 'villa'
      when 60 # Chalet
        property.type    = 'house'
        property.subtype = 'ski_chalet'
      when 80 # Bungalow
        property.type    = 'house'
        property.subtype = 'bungalow'
      when 110, 112 # Studio, Duplex
        property.type    = 'apartment'
        property.subtype = 'studio_bachelor'
      when 120 # Penthouse
        property.type    = 'apartment'
        property.subtype = 'luxury_apartment'
      when 130 # Hotel
        property.type    = 'others'
        property.subtype = 'hotel'
      when 140 # Lodge
        property.type    = 'house'
        property.subtype = 'cabin'
      when 160 # Apartment
        property.type    = 'apartment'
        property.subtype = 'apartment'
      when 70, 90, 95, 100, 145, 150 # Farmhouse, Boat, House Boat, Holiday Home, Riad, Mobile Home
        property.type    = 'house'
        property.subtype = 'house'
      end
    end

    def set_images
      images = payload['MediaV2'][0]['TypeContents']

      images.each do |image|
        url        = image['Versions'][0]['URL'] # biggest
        identifier = url.split('/').last # filename

        roomorama_image = Roomorama::Image.new(identifier).tap do |i|
          i.url     = ['http://', url].join
          i.caption = image['Tag']
        end

        property.add_image(roomorama_image)
      end
    end

    def set_price_and_availabilities
      periods        = payload['AvailabilityPeriodV1'].map { |period| AvailabilityPeriod.new(period) }
      actual_periods = periods.select(&:valid?)


      min_price  = actual_periods.map(&:daily_price).min
      dates_size = actual_periods.map { |period| period.dates.size }

      property.currency     = Price::CURRENCY
      property.minimum_stay = dates_size.min
      property.nightly_rate = min_price
      property.weekly_rate  = min_price * 7
      property.monthly_rate = min_price * 30
    end

    def code_for(item)
      {
        smoking_allowed: 81,
        pets_allowed:    83
      }.fetch(item)
    end

    def amenity_ids
      payload['PROP_INFO']['PROP_AMENITIES']
    end

    def pets_allowed?
      amenity_ids.include?(PETS_ALLOWED_AMENITY_ID)
    end

  end
end

