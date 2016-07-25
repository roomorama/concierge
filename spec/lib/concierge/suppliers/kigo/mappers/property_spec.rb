require 'spec_helper'

RSpec.describe Kigo::Mappers::Property do
  include Support::Fixtures

  let(:references) {
    {
      amenities: JSON.parse(read_fixture('kigo/amenities.json'))['AMENITY'],
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


    context 'rates' do
      let(:property_rate) {
        {
          'PROP_RATE_CURRENCY'     => "EUR",
          'PROP_RATE_NIGHTLY_FROM' => "151.98",
          'PROP_RATE_NIGHTLY_TO'   => "417.18",
          'PROP_RATE_WEEKLY_FROM'  => nil,
          'PROP_RATE_WEEKLY_TO'    => nil,
          'PROP_RATE_MONTHLY_FROM' => nil,
          'PROP_RATE_MONTHLY_TO'   => nil
          }
      }
      
      it 'sets price of valid period' do
        property_data['PROP_RATE'] = property_rate
        property = subject.prepare(property_data).value

        expect(property.nightly_rate).to eq 100
        expect(property.weekly_rate).to eq 700
        expect(property.monthly_rate).to eq 3000
      end
    end

    context 'description' do
      it 'sets short description if origin description is blank' do
        property_data['PROP_INFO']['PROP_DESCRIPTION'] = ''
        property = subject.prepare(property_data).value

        expect(property.description).to eq 'Short description'
      end

      it 'sets area description if origin and short description are blank' do
        property_data['PROP_INFO']['PROP_DESCRIPTION'] = ''
        property_data['PROP_INFO']['PROP_SHORTDESCRIPTION'] = ''
        property = subject.prepare(property_data).value

        expect(property.description).to eq 'Area description'
      end
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
      expect(property.floor).to eq 3
      expect(property.pets_allowed).to eq true
      expect(property.smoking_allowed).to eq false
      expect(property.cancellation_policy).to eq 'super_elite'
      expect(property.default_to_available).to eq true
      expect(property.check_in_time).to eq '15:00'
      expect(property.check_out_time).to eq '10:00'
      expect(property.country_code).to eq 'IT'
      expect(property.city).to eq 'Gallipoli'
      expect(property.neighborhood).to eq 'Puglia'
      expect(property.postal_code).to eq '73014'
      expect(property.address).to eq 'Strada Provinciale 215'
      expect(property.apartment_number).to eq '12'
      expect(property.lat).to eq '39.982447'
      expect(property.lng).to eq '18.015175'
      expect(property.number_of_double_beds).to eq 1
      expect(property.number_of_single_beds).to eq 4
      expect(property.number_of_sofa_beds).to eq 0
      expect(property.amenities).to eq ['wheelchairaccess', 'tv', 'kitchen']
      expect(property.type).to eq 'house'
      expect(property.subtype).to eq 'villa'

      # expect(property.security_deposit_amount).to eq 500
      # expect(property.services_cleaning).to eq true
      # expect(property.services_cleaning_required).to eq true
      # expect(property.services_cleaning_rate).to eq 150

      expect(property.minimum_stay).to eq 3
      expect(property.nightly_rate.to_i).to eq 57
      expect(property.weekly_rate.to_i).to eq 402
      expect(property.monthly_rate.to_i).to eq 1722

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
