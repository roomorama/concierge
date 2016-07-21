require 'spec_helper'

RSpec.describe Kigo::Mappers::Amenities do
  include Support::Fixtures

  let(:amenities) { JSON.parse(read_fixture('kigo/amenities.json')) }
  subject { described_class.new(amenities['AMENITY']) }

  describe '#map' do

    it { expect(subject.map(['unknown id'])).to eq [] }
    it { expect(subject.map([])).to eq [] }

    it 'sets proper amenities list' do
      ids = [
        1,  # Elevator
        57, # Shared kitchen
        63, # Air-conditioning
        71, # Pool - private
        72, # Pool - shared
        77  # Towels provided
      ]
      amenities = subject.map(ids)

      expect(amenities).to eq ['elevator', 'airconditioning', 'pool', 'kitchen']
      expect(amenities).not_to include('bed_linen_and_towels')
    end

    it 'sets bed linen and towel amenity' do
      ids = [
        16, # Bed linen provided
        77  # Towels provided
      ]
      amenities = subject.map(ids)

      expect(amenities).to eq ['bed_linen_and_towels']
    end

    it 'returns the amenities list' do
      property_data     = JSON.parse(read_fixture('kigo/property_data.json'))
      amenity_ids       = property_data['PROP_INFO']['PROP_AMENITIES']
      fixture_amenities = ['wheelchairaccess', 'tv', 'kitchen']

      expect(subject.map(amenity_ids)).to eq fixture_amenities
    end
  end
end