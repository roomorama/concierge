require 'spec_helper'

RSpec.describe AtLeisure::Mapper do
  include Support::Fixtures

  subject { described_class.new }

  describe '#prepare' do
    let(:property_data) { JSON.parse(read_fixture('atleisure/property_data.json')) }

    it 'returns the result with roomorama property accordingly provided data' do
      result = subject.prepare(property_data)

      expect(result).to be_success

      property = result.value

      expect(property).to be_a Roomorama::Property
      expect(property.identifier).to eq 'XX-1234-05'

      attributes = %w(title description number_of_bedrooms number_of_bathrooms surface surface_unit
                      max_guests currency city postal_code lat lng amenities type subtype
                      images nightly_rate weekly_rate monthly_rate calendar)
      attributes.each do |attribute|
        expect(property.send(attribute)).to_not be_blank
      end

      expect(property.validate!).to be true
    end
  end

end