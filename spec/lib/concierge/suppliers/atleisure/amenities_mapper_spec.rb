require 'spec_helper'

RSpec.describe AtLeisure::AmenitiesMapper do
  include Support::Fixtures

  subject { described_class.new }

  describe '#map' do
    let(:property_data) { JSON.parse(read_fixture('atleisure/property_data.json')) }
    let(:amenities_text) {
      'On 1st floor: (Livingroom(Single sofa bed, TV(cable), balcony), Kitchen(cooker(ceramic), oven, dishwasher, fridge freezer), \
          Bedroom(Double bed), Bedroom(Double bed), Bathroom(shower, washbasin, toilet))'
    }

    it 'sets proper amenities list' do
      property_data['LanguagePackENV4']['LayoutSimple'] = amenities_text
      amenities = subject.map(property_data)

      expect(amenities).to eq ['cabletv', 'kitchen', 'balcony', 'tv']
    end

    it 'returns the amenities list' do
      amenities = subject.map(property_data)
      fixture_amenities = ['kitchen', 'balcony', 'parking']

      expect(amenities).to be_a Array
      expect(amenities).to eq fixture_amenities
    end
  end
end