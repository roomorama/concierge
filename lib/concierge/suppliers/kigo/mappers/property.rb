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
      set_property_type
      # set_deposit
      # set_cleaning_service

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
      property.title                 = info['PROP_NAME']
      property.number_of_bedrooms    = info['PROP_BEDROOMS']
      property.number_of_bathrooms   = info['PROP_BATHROOMS']
      property.surface               = info['PROP_SIZE']
      property.surface_unit          = surface_unit(info['PROP_SIZE_UNIT'])
      property.max_guests            = info['PROP_MAXGUESTS']
      property.floor                 = info['PROP_FLOOR']
      property.pets_allowed          = amenity_ids.include?(code_for(:pets_allowed))
      property.smoking_allowed       = amenity_ids.include?(code_for(:smoking_allowed))
      property.cancellation_policy   = CANCELLATION_POLICY
      property.default_to_available  = true
      property.check_in_time         = info['PROP_CIN_TIME']
      property.check_out_time        = info['PROP_COUT_TIME']
      property.check_in_instructions = info['PROP_ARRIVAL_SHEET']
      property.minimum_stay          = stay_length(info['PROP_STAYTIME_MIN'])

      property.country_code     = info['PROP_COUNTRY']
      property.city             = info['PROP_CITY']
      property.neighborhood     = info['PROP_REGION']
      property.postal_code      = info['PROP_POSTCODE']
      property.address          = street_address
      property.apartment_number = info['PROP_APTNO']
      coordinates               = info['PROP_LATLNG']
      property.lat              = coordinates['LATITUDE']
      property.lng              = coordinates['LONGITUDE']
    end

    # returns days count computed by NIGHT, MONTH, YEAR unit
    def stay_length(period)
      multiplier = { 'MONTH' => 30, 'YEAR' => 365 }.fetch(period['UNIT'], 1)
      period['NUMBER'] * multiplier
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

    def set_property_type
      mapper                          = PropertyType.new(references[:property_types])
      property.type, property.subtype = mapper.map(info['PROP_TYPE_ID'])
    end

    def set_deposit

    end

    def set_cleaning_service
      return if pricing_setup["PRICING"].nil? || pricing_setup["PRICING"]["FEES"].nil? # No fees information
      fees          = pricing_setup["PRICING"]["FEES"]["FEES"]
      fees_currency = pricing_setup["PRICING"]["CURRENCY"]
      return if fees.empty? # No fees

      kigo_fees        = self.fees_mapping
      kigo_fees_hashed = kigo_fees.inject({}) do |hashed, kfee|
        hashed[kfee["FEE_TYPE_ID"]] = kfee
        hashed
      end

      fees_description = ""
      fees.each do |fee|
        fee_type = fee["FEE_TYPE_ID"]
        if fee_type == 3
          room.cleaningservice          = true
          room.cleaningservice_cost     = get_fee_value(fee)
          room.cleaningservice_required = !!fee["INCLUDE_IN_RENT"]
        elsif get_fee_value(fee) > 0
          fees_description = "\n\n *** Room Fees ***\n" if fees_description.empty?
          fees_description << "#{kigo_fees_hashed[fee_type]['FEE_TYPE_LABEL']}: #{fees_currency} #{display_fee_and_unit(fee)}\n"
        end
      end

      room.descriptions[:en] << fees_description if room.descriptions[:en]

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

    def set_price
      rate = payload['PROP_RATE']

      property.currency     = rate['PROP_RATE_CURRENCY']
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

