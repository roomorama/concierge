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

    attr_reader :property, :payload, :references, :pricing

    def initialize(references)
      @references = references
    end

    # manages data and returns the result with +Roomorama::Property+
    def prepare(property_data, pricing)
      build_room(property_data, pricing)
      property.instant_booking!

      set_base_info
      set_description
      set_beds_count
      set_amenities
      set_property_type
      set_price

      set_deposit
      set_cleaning_service

      Result.new(property)
    end

    private

    def build_room(property_data, pricing)
      @payload  = Concierge::SafeAccessHash.new(property_data)
      @property = Roomorama::Property.new(property_data['PROP_ID'].to_s)
      @pricing  = pricing
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
      deposit                          = pricing['DEPOSIT']
      property.security_deposit_amount = deposit['VALUE'].to_f if deposit
    end

    def set_cleaning_service
      cleaning_fee = pricing['FEES']['FEES'].find { |fee| fee['FEE_TYPE_ID'] == code_for(:cleaning_fee) }

      return unless cleaning_fee

      property.services_cleaning = true
      property.services_cleaning_required = cleaning_fee['INCLUDE_IN_RENT']
      property.services_cleaning_rate = get_fee_amount(cleaning_fee['VALUE']).to_f
    end

    def get_fee_amount(amount)
      return amount if amount.is_a?(String)
      amount['AMOUNT_ADULT']
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
      pricing_mapper = PricingSetup.new(payload['PROP_RATE'], pricing)

      property.currency     = pricing_mapper.currency
      property.nightly_rate = pricing_mapper.nightly_rate
      property.weekly_rate  = pricing_mapper.weekly_rate
      property.monthly_rate = pricing_mapper.monthly_rate
    end

    def code_for(item)
      {
        cleaning_fee:    3,
        smoking_allowed: 81,
        pets_allowed:    83
      }.fetch(item)
    end

    def amenity_ids
      payload['PROP_INFO']['PROP_AMENITIES']
    end

  end
end

