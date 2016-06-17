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
      set_images
      set_price_and_availabilities
      Result.new(property)
    end

    private

    def build_room(property_data)
      @meta_data          = property_data
      @property           = Roomorama::Property.new(property_data['HouseCode'])
      @property.amenities = []
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

    def set_amenities
      basic         = meta_data['LanguagePackENV4']
      layout_simple = basic['LayoutSimple']

      amenities_map.each do |key, value|
        property.amenities << key.to_s if Array(value).any? { |v| layout_simple.include?(v) }
      end

      costs_on_site = basic['CostsOnSite']

      deposit = costs_on_site.find { |cost| cost['Description'] == 'Deposit' }
      if deposit && match = deposit['Value'].match(/\d+/)
        property.security_deposit_amount        = match[0].to_i
        property.security_deposit_type          = 'cash'
        property.security_deposit_currency_code = Price::CURRENCY
      end

      bed_linen = costs_on_site.find { |cost| cost['Description'] == 'Bed linen' && cost['Value'] == 'Included' }
      towels    = costs_on_site.find { |cost| cost['Bath towels'] == 'Bed linen' && cost['Value'] == 'Included' }
      property.amenities << 'bed_linen_and_towels' if bed_linen && towels

      cleaning = costs_on_site.find { |cost| cost['Description'] == 'Cleaning' }
      if cleaning
        property.services_cleaning = true
        if cleaning['Value'] =~ /Obliged|Mandatory/
          property.services_cleaning_required = true
          property.services_cleaning_rate     = cleaning['Value'].match(/\d+/)[0]
        end

        property.amenities << 'free_cleaning' if cleaning['Value'] =~ /Included/
      end

      property_items = meta_data['PropertiesV1'].detect { |data_hash| data_hash['TypeNumber'] == 50 }
      if property_items
        property.smoking_allowed = property_items['TypeContents'].include?(504)
        property.amenities       += ['wifi', 'internet'] if property_items['TypeContents'].include?(510) #wifi
      end
    end

    def set_beds_count
      beds_layout = layout_items.find { |item| item.code == code_for(:beds) }
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

    def set_property_type
      properties_array = meta_data['PropertiesV1']
      room_type_hash   = properties_array.detect { |data_hash| data_hash['TypeNumber'] == 10 }
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
          i.url     = url
          i.caption = image['Tag']
        end

        property.add_image(roomorama_image)
      end
    end

    def set_price_and_availabilities
      periods        = meta_data['AvailabilityPeriodV1'].map { |period| AvailabilityPeriod.new(period) }
      actual_periods = periods.select(&:actual?)

      min_price = actual_periods.map(&:price).min

      property.nightly_rate = min_price
      property.weekly_rate  = min_price * 7
      property.monthly_rate = min_price * 30

      actual_periods.each do |period|
        period.dates.each do |date|
          property.update_calendar(date => true)
        end
      end
    end

    def code_for(item)
      {
        floors:     50,
        rooms:      100,
        beds:       200,
        room_items: 400,
        kitchen:    500,
        washing:    600
      }.fetch(item)
    end

    def amenities_map
      {
        airconditioning:  'airconditioning',
        cabletv:          'TV',
        elevator:         'lift',
        gym:              'fitness',
        wheelchairaccess: 'single bed adapted for disabled',
        internet:         'internet',
        kitchen:          'kitchen',
        parking:          'parking',
        pool:             ['swimmingpool', 'Poolhouse'],
        tv:               'TV',
        laundry:          'dryer'
      }
    end

    AvailabilityPeriod = Struct.new(:period) do

      def check_in
        Date.parse(period['ArrivalDate'])
      end

      def check_out
        Date.parse(period['DepartureDate'])
      end

      def dates
        (check_in..check_out).to_a
      end

      def length
        check_out - check_in
      end

      def price
        period['Price'].to_f / dates.size
      end

      def actual?
        period['OnRequest'] == 'No' && check_in > Date.today
      end
    end

    LayoutItem = Struct.new(:data) do

      def code
        data['Type']
      end

      def name
        find_en_description(data)
      end

      def items
        @items ||= data['Items'].each_with_object({}) do |item, hash|
          hash[item['Number']] = find_en_description(item)
        end
      end

      private

      # retrieves english name of some reference parameter
      def find_en_description(item)
        item['Description'].find { |d| d['Language'] == 'EN' }['Description']
      end
    end
  end
end

