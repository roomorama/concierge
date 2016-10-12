module AtLeisure
  # +AtLeisure::Mapper+
  #
  # This class responsible for setting data and performing data to Roomorama format
  #
  # ==== Attributes
  #
  # * +layout_items+ - list of references data
  # * +property+     - +Roomorama::Property+ instance
  # * +meta_data+    - hash based AtLeisure payload
  #
  class Mapper
    CANCELLATION_POLICY = 'super_elite'

    CODES = {
      property_type:   10,
      main_items:      50,
      beds:            200,
      room_items:      400,
      smoking_allowed: 504,
      wifi:            510
    }

    attr_reader :layout_items, :property, :meta_data

    def initialize(layout_items:)
      @layout_items = layout_items.map { |item| LayoutItem.new(item) }
    end

    # manages data and returns the result with +Roomorama::Property+
    def prepare(property_data)
      build_room(property_data)
      property.instant_booking!

      set_base_info
      set_beds_count
      set_amenities
      set_deposit
      set_cleaning_service
      set_additional_info
      set_property_type
      set_images
      set_price_and_availabilities
      set_owner_info

      Result.new(property)
    end

    private

    def build_room(property_data)
      @meta_data = Concierge::SafeAccessHash.new(property_data)
      @property  = Roomorama::Property.new(property_data['HouseCode'])
    end

    def set_base_info
      info    = meta_data['BasicInformationV3']
      info_en = meta_data['LanguagePackENV4']

      property.title                = info['Name']
      property.description          = info_en['Description'] || info_en['ShortDescription']
      property.number_of_bedrooms   = info['NumberOfBedrooms']
      property.number_of_bathrooms  = info['NumberOfBathrooms'].to_f
      property.surface              = info['DimensionM2']
      property.surface_unit         = 'metric'
      property.max_guests           = info['MaxNumberOfPersons']
      property.pets_allowed         = info['NumberOfPets'] > 0
      property.currency             = Price::CURRENCY
      property.cancellation_policy  = CANCELLATION_POLICY
      property.default_to_available = false

      property.country_code = info['Country']
      property.city         = info_en['City']
      property.postal_code  = info['ZipPostalCode']
      property.lat          = info['WGS84Latitude']
      property.lng          = info['WGS84Longitude']
    end

    # Information taken from https://www.belvilla.com/contact-us
    # For some countries there are no information provided
    def set_owner_info
      property.owner_email = 'belvillapt@belvilla.com'
      country_info = {
        'AU' => ['Australia', '1800 442586'],
        'AT' => ['Austria', '0800 296669'],
        'BE' => ['Belgium', '(+32) 03 808 09 54'],
        'CA' => ['Canada', '1800 4045160'],
        'DK' => ['Denmark', '8088 7970'],
        'FR' => ['France', '0800 905 849'],
        'DE' => ['Germany', '0800 1826013'],
        'IE' => ['Ireland', '1800 552175'],
        'IT' => ['Italy', '800 871005'],
        'LU' => ['Luxembourg', '8002 6106'],
        'NL' => ['Netherlands', '(+31) 088 202 12 12'],
        'NO' => ['Norway', '800 19321'],
        'PL' => ['Poland', '(+48) 22 3988048'],
        'PT' => ['Portugal', '8008 31532'],
        'ES' => ['Spain', '900 983103'],
        'SE' => ['Sweden', '020 794849'],
        'CH' => ['Switzerland', '0800 561913'],
        'GB' => ['United Kingdom', '0800 0516731'],
        'US' => ['United States', '1 800 7197573']
      }
      info = meta_data['BasicInformationV3']
      if country_info.has_key?(info['Country'])
        property.owner_city, property.owner_phone_number = country_info[info['Country']]
      end
    end

    # payload presents beds size as different named items
    def set_beds_count
      beds_layout = layout_items.find { |item| item.number == code_for(:beds) }
      double_beds = 0
      single_beds = 0
      sofa_beds   = 0

      meta_data['LayoutExtendedV2'].each do |entry|
        item = entry['Item']
        num  = entry['NumberOfItems']

        case beds_layout.items[item]
          when /double/i, /2.pers/
            double_beds += num
          when /sofa/
            sofa_beds += num
          when /single/i, /1.pers/
            single_beds += num
        end
      end

      property.number_of_double_beds = double_beds
      property.number_of_single_beds = single_beds
      property.number_of_sofa_beds   = sofa_beds
    end

    def set_amenities
      property.amenities = amenities_mapper.map(meta_data)
    end

    def amenities_mapper
      AmenitiesMapper.new
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

      property.services_cleaning = cleaning['Payment'] != 'None'

      if property.services_cleaning
        if cleaning['Payment'] == 'Inclusive'
          property.amenities << 'free_cleaning'
          property.services_cleaning_required = false
          property.services_cleaning_rate     = 0
        else
          property.services_cleaning_required = cleaning['Payment'] == 'Mandatory'
          property.services_cleaning_rate     = cleaning['Amount']
        end
      end
    end

    def set_additional_info
      property_items = meta_data['PropertiesV1'].detect { |data_hash| data_hash['TypeNumber'] == code_for(:main_items) }
      if property_items
        property.smoking_allowed = property_items['TypeContents'].include?(code_for(:smoking_allowed))
        property.amenities       += ['wifi', 'internet'] if property_items['TypeContents'].include?(code_for(:wifi))
      end
    end

    # sets type and subtype accordingly related code
    def set_property_type
      properties_array = Array(meta_data['PropertiesV1'])
      room_type_hash   = properties_array.find { |data_hash| data_hash['TypeNumber'] == code_for(:property_type) }.to_h
      room_type_number = Array(room_type_hash['TypeContents']).first

      # There are also hotel (130), mill (172), tent lodge (175)
      # we ignore them and filter them out during property validation
      case room_type_number
        when 20 # Castle
          property.type    = 'house'
          property.subtype = 'chateau'
        when 30 # Cottage
          property.type    = 'house'
          property.subtype = 'cottage'
        when 40 # Mansion
          property.type    = 'house'
        when 50 # Villa
          property.type    = 'house'
          property.subtype = 'villa'
        when 60 # Chalet
          property.type    = 'house'
        when 80 # Bungalow
          property.type    = 'house'
          property.subtype = 'bungalow'
        when 110, 112 # Studio, Duplex
          property.type    = 'apartment'
          property.subtype = 'studio_bachelor'
        when 120 # Penthouse
          property.type    = 'apartment'
          property.subtype = 'luxury_apartment'
        when 140 # Lodge
          property.type    = 'house'
          property.subtype = 'cabin'
        when 160 # Apartment
          property.type    = 'apartment'
        when 70, 90, 95, 100, 145, 150, 170 # Farmhouse, Boat, House Boat, Holiday Home, Riad, Mobile Home, Cave house
          property.type    = 'house'
      end
    end

    def set_images
      images = meta_data['MediaV2'][0]['TypeContents']

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
      actual_stays = meta_data['AvailabilityPeriodV1'].select { |availability|
        validator(availability).valid?
      }.map { |period| to_stay(period) }

      min_price  = actual_stays.map(&:rate).min
      min_stay = actual_stays.map(&:length).min

      property.minimum_stay = min_stay
      property.nightly_rate = min_price
      property.weekly_rate  = min_price * 7
      property.monthly_rate = min_price * 30
    end

    def code_for(item)
      CODES.fetch(item)
    end

    def find_cost(name)
      cost = meta_data['CostsOnSiteV1'].find { |cost| cost_description(cost) == name }
      cost['Items'].first if cost
    end

    def cost_description(cost)
      cost['TypeDescriptions'].find { |d| d['Language'] == 'EN' }['Description']
    end

    private

    def to_stay(period)
      Roomorama::Calendar::Stay.new({
        checkin:    period['ArrivalDate'],
        checkout:   period['DepartureDate'],
        price:      period['Price'].to_f,
      })
    end

    def validator(availability)
      ::AtLeisure::AvailabilityValidator.new(availability)
    end
  end
end

