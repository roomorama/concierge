require 'spec_helper'

RSpec.describe AtLeisure::AmenitiesMapper do
  include Support::Fixtures

  subject { described_class.new }

  describe '#map' do
    let(:property_data) { JSON.parse(read_fixture('atleisure/property_data.json')) }

    it 'returns the amenities list' do
      amenities = subject.map(property_data)
      fixture_amenities = ['kitchen', 'balcony', 'parking']

      expect(amenities).to be_a Array
      expect(amenities).to include *fixture_amenities
    end
  end
end