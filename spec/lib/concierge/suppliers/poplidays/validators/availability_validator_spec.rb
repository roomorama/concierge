require 'spec_helper'

RSpec.describe Poplidays::Validators::AvailabilityValidator do

  let(:invalid_availabilities) do
    [
      {'requestOnly' => true, 'priceEnabled' => true, 'arrival' => '2016-06-20'}, # on requests stay
      {'requestOnly' => false, 'priceEnabled' => false, 'arrival' => '2016-06-20'}, # price disabled stay
      {'requestOnly' => false, 'priceEnabled' => true, 'arrival' => '2016-06-18'} # too old
    ]
  end
  let(:valid_availability) { {'requestOnly' => false, 'priceEnabled' => true, 'arrival' => '2016-06-20'} }
  let(:today) { Date.new(2016, 6, 18) }

  describe '#valid?' do
    it 'returns true for valid availability' do
      validator = described_class.new(valid_availability, today)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on invalid availability' do
      invalid_availabilities.each do |availability|
        validator = described_class.new(availability, today)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end