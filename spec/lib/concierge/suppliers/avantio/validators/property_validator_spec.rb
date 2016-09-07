require 'spec_helper'

RSpec.describe Avantio::Validators::PropertyValidator do

  let(:invalid_properties) do
    [
      double(master_kind_code: '3', bedrooms: 2), # Hotel
      double(master_kind_code: '2', bedrooms: nil), # Unknown bedrooms count
    ]
  end
  let(:valid_property) do
    double(master_kind_code: '2', bedrooms: 2)
  end

  describe '#valid?' do
    it 'returns true for valid rate' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid rates' do
      invalid_properties.each do |property|
        validator = described_class.new(property)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end
