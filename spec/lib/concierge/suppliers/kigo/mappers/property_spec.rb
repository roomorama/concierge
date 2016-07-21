require 'spec_helper'

RSpec.describe Kigo::Mappers::Property do
  include Support::Fixtures

  let(:references) {
    {
      amenities: JSON.parse(read_fixture('kigo/amenities.json')),
      property_types: JSON.parse(read_fixture('kigo/property_types.json')),
      fee_types: JSON.parse(read_fixture('kigo/fee_types.json'))
    }
  }


  subject { described_class.new(references) }

  describe '#prepare' do
    let(:property_data) { JSON.parse(read_fixture('kigo/property_data.json')) }

    context 'images' do
      let(:image) {
        {
          'PHOTO_ID'        => '//supper-fantastic.url/hashed-identifier.jpg',
          'PHOTO_PANORAMIC' => false,
          'PHOTO_NAME'      => 'Balcony',
          'PHOTO_COMMENTS'  => ''
        }
      }

      it 'sets proper image data' do
        property_data['PROP_PHOTOS'] = [image]
        property = subject.prepare(property_data).value

        expect(property.images.size).to eq 1
        image = property.images.first
        expect(image.url).to eq 'https://supper-fantastic.url/hashed-identifier.jpg'
        expect(image.identifier).to eq 'hashed-identifier.jpg'
        expect(image.caption).to eq 'Balcony'
      end

    end

    context 'beds count' do
      let(:single_beds) { { 'Item' => 10002, 'NumberOfItems' => 2 } }
      let(:double_beds) { { 'Item' => 10012, 'NumberOfItems' => 3 } }
      let(:sofa_beds)   { { 'Item' => 10008, 'NumberOfItems' => 1 } }

      it 'calculates correct number of items' do
        property_data['LayoutExtendedV2'] = [single_beds, double_beds, sofa_beds]
        property = subject.prepare(property_data).value

        expect(property.number_of_single_beds).to eq 2
        expect(property.number_of_double_beds).to eq 3
        expect(property.number_of_sofa_beds).to eq 1
      end
    end

    context 'rates' do
      let(:on_request_period) {
        {
          'Quantity'           => 1,
          'ArrivalDate'        => '2017-12-04',
          'ArrivalTimeFrom'    => '16:00',
          'ArrivalTimeUntil'   => '18:00',
          'DepartureDate'      => '2017-12-11',
          'DepartureTimeFrom'  => '09:00',
          'DepartureTimeUntil' => '10:00',
          'OnRequest'          => 'Yes',
          'Price'              => 681,
          'PriceExclDiscount'  => 681
        }
      }
      let(:valid_period) {
        {
          'Quantity'           => 1,
          'ArrivalDate'        => '2017-12-04',
          'ArrivalTimeFrom'    => '16:00',
          'ArrivalTimeUntil'   => '18:00',
          'DepartureDate'      => '2017-12-11',
          'DepartureTimeFrom'  => '09:00',
          'DepartureTimeUntil' => '10:00',
          'OnRequest'          => 'No',
          'Price'              => 800,
          'PriceExclDiscount'  => 800
        }
      }

      it 'sets price of valid period' do
        property_data['AvailabilityPeriodV1'] = [on_request_period, valid_period]
        property = subject.prepare(property_data).value

        expect(property.minimum_stay).to eq 8
        expect(property.nightly_rate).to eq 100
        expect(property.weekly_rate).to eq 700
        expect(property.monthly_rate).to eq 3000
      end
    end

    it 'sets short description if origin description blank' do
      property_data['LanguagePackENV4']['Description'] = nil
      property = subject.prepare(property_data).value

      expect(property.description).to eq "sdfg sdfg sd gsdf g sdfg sdfg sdf gsd fg sdf gd"
    end

    it 'returns the result with roomorama property accordingly provided data' do
      result = subject.prepare(property_data)
      expect(result).to be_success

      property = result.value
      expect(property.identifier).to eq '237294'
      expect(property.instant_booking).to be true
      expect(property.title).to eq 'Villa immersa nel verde  700 metri primo lido '
      expect(property.description).to include 'Bellissima soluzione in località Gallipoli Punta Pizzo'
      expect(property.number_of_bedrooms).to eq 3
      expect(property.number_of_bathrooms).to eq 2
      expect(property.surface).to eq '37674'
      expect(property.surface_unit).to eq 'imperial'
      expect(property.max_guests).to eq 9
      expect(property.pets_allowed).to eq true
      expect(property.cancellation_policy).to eq 'super_elite'
      expect(property.default_to_available).to eq true
      expect(property.country_code).to eq 'IT'
      expect(property.city).to eq 'Gallipoli'
      expect(property.neighborhood).to eq 'Puglia'
      expect(property.postal_code).to eq '73014'
      expect(property.lat).to eq "39.982447"
      expect(property.lng).to eq "18.015175"
      # expect(property.number_of_double_beds).to eq 4
      # expect(property.number_of_single_beds).to eq 2
      # expect(property.number_of_sofa_beds).to eq 0
      expect(property.amenities).to eq ['kitchen', 'balcony', 'parking']
      # expect(property.security_deposit_amount).to eq 500
      # expect(property.services_cleaning).to eq true
      # expect(property.services_cleaning_required).to eq true
      # expect(property.services_cleaning_rate).to eq 150
      # expect(property.smoking_allowed).to eq false
      # expect(property.type).to eq 'house'
      # expect(property.subtype).to eq 'house'
      # expect(property.minimum_stay).to eq 3
      # expect(property.nightly_rate.to_i).to eq 57
      # expect(property.weekly_rate.to_i).to eq 402
      # expect(property.monthly_rate.to_i).to eq 1722
      # expect(property.images.size).to eq 9
      #
      # image = property.images.first
      # expect(image.identifier).to eq '211498_lsr_2013110590534673451.jpg'
      # expect(image.url).to eq 'http://cdn.leisure-group.net/photo/web/600x400/211498_lsr_2013110590534673451.jpg'
      #
      # expect(property.validate!).to be true
    end
  end
end
