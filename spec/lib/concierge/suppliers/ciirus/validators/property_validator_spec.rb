require 'spec_helper'

RSpec.describe Ciirus::Validators::PropertyValidator do

  let(:invalid_country_property) { double(type: 'Unspecified', country: '654987')}
  let(:invalid_type_property) { double(type: 'Unspecified', country: 'Turkey')}
  let(:valid_property) { double(type: 'Motel', country: 'USA')}

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for property with invalid type' do
      validator = described_class.new(invalid_type_property)
      expect(validator.valid?).to be_falsey
    end

    it 'returns false for property with invalid country' do
      validator = described_class.new(invalid_country_property)
      expect(validator.valid?).to be_falsey
    end
  end
end
