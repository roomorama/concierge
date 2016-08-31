require 'spec_helper'

RSpec.describe AtLeisure::AvailabilityValidator do

  let(:valid_availability) do
    {
      'Quantity' => 2,
      'ArrivalDate' => '2016-11-27',
      'ArrivalTimeFrom' => '17:00',
      'ArrivalTimeUntil' => '20:00',
      'DepartureDate' => '2016-11-29',
      'DepartureTimeFrom' => '10:00',
      'DepartureTimeUntil' => '12:00',
      'OnRequest' => 'No',
      'Price' => 160,
      'PriceExclDiscount' => 160
    }
  end
  let(:invalid_availabilities) do
    [
      {
        'Quantity' => 2,
        'ArrivalDate' => '2016-11-26',
        'ArrivalTimeFrom' => '17:00',
        'ArrivalTimeUntil' => '20:00',
        'DepartureDate' => '2016-11-29',
        'DepartureTimeFrom' => '10:00',
        'DepartureTimeUntil' => '12:00',
        'OnRequest' => 'No',
        'Price' => 160,
        'PriceExclDiscount' => 160
      }, # too old
      {
        'Quantity' => 2,
        'ArrivalDate' => '2016-11-27',
        'ArrivalTimeFrom' => '17:00',
        'ArrivalTimeUntil' => '20:00',
        'DepartureDate' => '2016-11-29',
        'DepartureTimeFrom' => '10:00',
        'DepartureTimeUntil' => '12:00',
        'OnRequest' => 'Yes',
        'Price' => 160,
        'PriceExclDiscount' => 160
      }, # on request only
    ]
  end
  let(:today) { Date.new(2016, 11, 26) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  describe '#valid?' do

    it 'returns true for valid availability' do
      validator = described_class.new(valid_availability)
      expect(validator.valid?).to be true
    end

    it 'returns false for invalid properties' do
      invalid_availabilities.each do |availability|
        validator = described_class.new(availability)
        expect(validator.valid?).to be false
      end
    end
  end
end