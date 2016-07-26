require 'spec_helper'

RSpec.describe Poplidays::Validators::AvailabilityValidator do

  let(:invalid_availabilities) do
    [
      {'requestOnly' => true, 'priceEnabled' => true}, # on requests stay
      {'requestOnly' => false, 'priceEnabled' => false} # price disabled stay
    ]
  end
  let(:valid_availability) { {'requestOnly' => false, 'priceEnabled' => true} }

  describe '#valid?' do
    it 'returns true for valid availability' do
      validator = described_class.new(valid_availability)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on invalid availability' do
      invalid_availabilities.each do |availability|
        validator = described_class.new(availability)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end