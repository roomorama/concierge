require 'spec_helper'

RSpec.describe Kigo::Mappers::Property do
  include Support::Fixtures

  let(:references) {
    {
      amenities: JSON.parse(read_fixture('kigo/amenities.json')),
      property_types: JSON.parse(read_fixture('kigo/property_types.json')),
    }
  }


  subject { described_class.new(references) }

  describe '#prepare' do
    let(:property_data) { JSON.parse(read_fixture('kigo/property_data.json')) }
    let(:pricing) { JSON.parse(read_fixture('kigo/pricing_setup.json'))['PRICING'] }
    let(:expected_nightly_rate) { 151.98 }
    context 'images' do
      let(:image) {
        {
          'PHOTO_ID'        => '//supper-fantastic.url/hashed-identifier.jpg',
          'PHOTO_PANORAMIC' => false,
          'PHOTO_NAME'      => 'Balcony',
          'PHOTO_COMMENTS'  => 'Balcony with foosball table'
        }
      }

      it 'sets proper image data' do
        property_data['PROP_PHOTOS'] = [image]
        property = subject.prepare(property_data, pricing).value

        expect(property.images.size).to eq 1
        image = property.images.first
        expect(image.url).to eq 'https://supper-fantastic.url/hashed-identifier.jpg'
        expect(image.identifier).to eq 'hashed-identifier.jpg'
        expect(image.caption).to eq 'Balcony with foosball table'
      end
    end

    context 'stay length' do
      context 'unit is month' do
        let(:minimum_stay) {
          {
            'UNIT' => 'MONTH',
            'NUMBER' => 1
          }
        }
        it 'sets value * 30' do
          property_data['PROP_INFO']['PROP_STAYTIME_MIN'] = minimum_stay
          property = subject.prepare(property_data, pricing).value

          expect(property.minimum_stay).to eq 30
        end
      end
    end

    context 'description' do
      it 'sets short description if origin description is blank' do
        property_data['PROP_INFO']['PROP_DESCRIPTION'] = ''
        property = subject.prepare(property_data, pricing).value

        expect(property.description).to eq 'Short description'
      end

      it 'sets area description if origin and short description are blank' do
        property_data['PROP_INFO']['PROP_DESCRIPTION'] = ''
        property_data['PROP_INFO']['PROP_SHORTDESCRIPTION'] = ''
        property = subject.prepare(property_data, pricing).value

        expect(property.description).to eq 'Area description'
      end
    end

    it 'returns the result with roomorama property accordingly provided data' do
      result = subject.prepare(property_data, pricing)
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
      expect(property.number_of_single_beds).to eq 5
      expect(property.number_of_sofa_beds).to eq 0
      expect(property.amenities).to eq ['wheelchairaccess', 'tv', 'kitchen']
      expect(property.type).to eq 'house'
      expect(property.subtype).to eq 'villa'

      expect(property.security_deposit_amount).to eq 150
      expect(property.services_cleaning).to eq true
      expect(property.services_cleaning_required).to eq false
      expect(property.services_cleaning_rate).to eq 30

      expect(property.minimum_stay).to eq 7
      expect(property.nightly_rate).to eq expected_nightly_rate
      expect(property.weekly_rate).to eq expected_nightly_rate * 7
      expect(property.monthly_rate).to eq expected_nightly_rate * 30

      expect(property.images.size).to eq 27

      image = property.images.first
      expect(image.identifier).to eq '95dec679-74ea-4a5c-babc-6b76eb4ea474.jpg'
      expect(image.url).to eq 'https://s3.amazonaws.com/cdnmedia.bookt.com/15826/95dec679-74ea-4a5c-babc-6b76eb4ea474.jpg'
      expect(image.caption).to eq 'Niiice'

      expect(property.validate!).to be true
    end
  end
end
