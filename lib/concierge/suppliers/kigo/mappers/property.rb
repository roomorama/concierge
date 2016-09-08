module Kigo::Mappers
  # +Kigo::Mappers::Property+
  #
  # This class responsible for setting data and performing data to Roomorama format
  #
  # ==== Attributes
  #
  # * +property+   - +Roomorama::Property+ instance
  # * +resolver+   - helps resolve differences between Kigo and Kigo Legacy
  # * +payload+    - hash based Kigo payload
  # * +references+ - list of references data
  # * +pricing+    - property prices details. Uses for setting deposit, cleaning service price and
  #                  additional prices if base prices hasn't provided
  #
  class Property
    # raises an error when base rates and +pricing+ not provided
    class NoPriceError < StandardError; end

    CANCELLATION_POLICY = 'super_elite'

    attr_reader :property, :payload, :references, :pricing, :resolver

    def initialize(references, resolver:)
      @references = references
      @resolver   = resolver
    end

    # manages data and returns the result with +Roomorama::Property+
    def prepare(property_data, pricing)
      build_property(property_data, pricing)
      property.instant_booking!

      set_base_info
      set_description
      set_beds_count
      set_amenities
      set_property_type
      set_price
      set_images

      set_deposit
      set_cleaning_service

      Result.new(property)
    rescue NoPriceError
      Result.error(:no_prices_provided)
    end

    private

    def build_property(property_data, pricing)
      @payload  = Concierge::SafeAccessHash.new(property_data)
      @property = Roomorama::Property.new(property_data['PROP_ID'].to_s)
      @pricing  = Concierge::SafeAccessHash.new(pricing)
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
      property.check_in_time         = info['PROP_CIN_TIME']
      property.check_out_time        = info['PROP_COUT_TIME']
      property.check_in_instructions = info['PROP_ARRIVAL_SHEET']
      property.minimum_stay          = stay_length(info['PROP_STAYTIME_MIN'])

      # Kigo properties are available by default, but most of them has a periodical rate
      # which covers almost all days. The days which not in periodical rates
      # have unavailable availabilities for these days
      property.default_to_available  = true

      property.country_code     = info['PROP_COUNTRY']
      property.city             = info['PROP_CITY']
      property.neighborhood     = info['PROP_REGION']
      property.postal_code      = info['PROP_POSTCODE']
      property.address          = street_address
      property.apartment_number = info['PROP_APTNO']

      coordinates = info['PROP_LATLNG']
      if coordinates
        property.lat = coordinates['LATITUDE']
        property.lng = coordinates['LONGITUDE']
      end
    end

    def stay_length(interval)
      Kigo::TimeInterval.new(interval).days
    end

    def set_description
      description      = strip(info['PROP_DESCRIPTION']) || strip(info['PROP_SHORTDESCRIPTION'])
      area_description = strip(info['PROP_AREADESCRIPTION'])

      property.description = [description, area_description].compact.join("\n")
    end

    def strip(string)
      string.to_s.strip unless string.to_s.strip.empty?
    end

    def surface_unit(name)
      name == 'SQFEET' ? 'imperial' : 'metric'
    end

    def street_address
      [
        info['PROP_STREETNO'],
        info['PROP_ADDR1'],
        info['PROP_ADDR2'],
        info['PROP_ADDR3']
      ].reject { |addr| addr.to_s.empty? }.join(', ')
    end

    def set_beds_count
      mapper = Beds.new(info['PROP_BED_TYPES'])

      property.number_of_double_beds = mapper.double_beds_size
      property.number_of_single_beds = mapper.single_beds_size
      property.number_of_sofa_beds   = mapper.sofa_beds_size
    end

    def set_amenities
      property.amenities = amenities_mapper.map(amenity_ids)
    end

    def amenities_mapper
      Amenities.new(references['amenities']['AMENITY'])
    end

    def set_property_type
      mapper                          = PropertyType.new(references['property_types'])
      property.type, property.subtype = mapper.map(info['PROP_TYPE_ID'])
    end

    def set_deposit
      deposit = pricing['DEPOSIT']

      return unless deposit

      property.security_deposit_amount = get_fee_amount(deposit)
    end

    def set_cleaning_service
      fees         = Array(pricing.get('FEES.FEES'))
      cleaning_fee = fees.find { |fee| fee['FEE_TYPE_ID'] == code_for(:cleaning_fee) }

      return unless cleaning_fee

      property.services_cleaning          = true
      property.services_cleaning_required = cleaning_fee['INCLUDE_IN_RENT']
      property.services_cleaning_rate     = get_fee_amount(cleaning_fee)
    end

    # STAYLENGTH unit means deposit has different prices for night, week, month
    # since Roomorama doesn't support variates of deposit, to be conservative
    # we are choosing maximum price
    def get_fee_amount(fee)
      if fee['UNIT'] == 'STAYLENGTH'
        fee['VALUE'].map { |item| fee_price(item['VALUE']) }.max
      else
        fee_price(fee['VALUE'])
      end
    end

    # Kigo +amount+ might be hash or integer
    # KigoLegacy +amount+ might be hash or string
    def fee_price(amount)
      amount.is_a?(Hash) ? amount['AMOUNT_ADULT'].to_i : amount.to_i
    end

    # images has differences between Kigo and KigoLegacy
    # using +resolver+ to resolve differences
    def set_images
      images = resolver.images(payload['PROP_PHOTOS'], property.identifier)
      images.each { |image| property.add_image(image) }
    end

    def set_price
      pricing_mapper = PricingSetup.new(payload['PROP_RATE'], pricing)

      raise NoPriceError unless pricing_mapper.valid?

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
      Array(payload['PROP_INFO']['PROP_AMENITIES'])
    end

  end
end

