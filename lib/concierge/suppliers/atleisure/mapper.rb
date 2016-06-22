module AtLeisure
  class Mapper

    attr_reader :layout_items, :property, :meta_data

    def initialize(layout_items:)
      @layout_items = layout_items.map { |item| LayoutItem.new(item) }
    end

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

      property.title               = info['Name']
      property.description         = info_en['Description']
      property.number_of_bedrooms  = info['NumberOfBedrooms']
      property.number_of_bathrooms = info['NumberOfBathrooms'].to_f
      property.surface             = info['DimensionM2']
      property.surface_unit        = 'metric'
      property.max_guests          = info['MaxNumberOfPersons']
      property.pets_allowed        = info['NumberOfPets'] > 0
      property.currency            = Price::CURRENCY

      property.country_code = info['Country']
      property.city         = info_en['City']
      property.postal_code  = info['ZipPostalCode']
      property.lat          = info['WGS84Latitude']
      property.lng          = info['WGS84Longitude']
    end

    def set_beds_count
      beds_layout = layout_items.find { |item| item.number == code_for(:beds) }
      double_beds = 0
      single_beds = 0
      sofa_beds   = 0

      meta_data['LayoutExtendedV2'].each do |entry|
        item = entry['Item']
        num  = entry['NumberOfItems']

        case beds_layout.items[item]
          when /double bed/, /queen size bed/
            double_beds += num
          when /sofa bed/
            sofa_beds += num
          when /bed\b/ # Doesn't match 'bedroom'
            single_beds += num
          when /sleeper/ # Sleepers are counted as beds
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

      property.services_cleaning          = cleaning['Payment'] != 'None'
      property.services_cleaning_required = cleaning['Payment'] == 'Mandatory'
      property.services_cleaning_rate     = cleaning['Amount']

      property.amenities << 'free_cleaning' if cleaning['Payment'] == 'Inclusive'
    end

    def set_additional_info
      property_items = meta_data['PropertiesV1'].detect { |data_hash| data_hash['TypeNumber'] == code_for(:main_items) }
      if property_items
        property.smoking_allowed = property_items['TypeContents'].include?(code_for(:smoking_allowed))
        property.amenities       += ['wifi', 'internet'] if property_items['TypeContents'].include?(code_for(:wifi))
      end
    end

    def set_property_type
      properties_array = meta_data['PropertiesV1']
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
      periods        = meta_data['AvailabilityPeriodV1'].map { |period| AvailabilityPeriod.new(period) }
      actual_periods = periods.select(&:valid?)

      min_price = actual_periods.map(&:price).min

      property.nightly_rate = min_price
      property.weekly_rate  = min_price * 7
      property.monthly_rate = min_price * 30

      actual_periods.each do |period|
        period.dates.each do |date|
          property.update_calendar(date.to_s => true)
        end
      end
    end

    def code_for(item)
      {
        property_type:   10,
        main_items:      50,
        beds:            200,
        room_items:      400,
        smoking_allowed: 504,
        wifi:            510
      }.fetch(item)
    end

    def find_cost(name)
      cost = meta_data['CostsOnSiteV1'].find { |cost| cost_description(cost) == name }
      cost['Items'].first if cost
    end

    def cost_description(cost)
      cost['TypeDescriptions'].find { |d| d['Language'] == 'EN' }['Description']
    end

  end
end

