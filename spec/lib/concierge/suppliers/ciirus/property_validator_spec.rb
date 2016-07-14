require 'spec_helper'

RSpec.describe Ciirus::PropertyValidator do

  let(:invalid_property) { double(type: 'Unspecified')}
  let(:valid_property) { double(type: 'Motel')}


  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid property' do
      validator = described_class.new(invalid_property)
      expect(validator.valid?).to be_falsey
    end
  end
end
