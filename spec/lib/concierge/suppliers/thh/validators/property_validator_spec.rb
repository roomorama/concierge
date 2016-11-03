require 'spec_helper'

RSpec.describe THH::Validators::PropertyValidator do

  let(:invalid_property) { { 'instant_confirmation' => false } }
  let(:valid_property) { { 'instant_confirmation' => true } }

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid cases' do
      validator = described_class.new(invalid_property)
      expect(validator.valid?).to be_falsey
    end
  end
end
