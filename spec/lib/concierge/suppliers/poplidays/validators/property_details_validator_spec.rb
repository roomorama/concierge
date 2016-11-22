require 'spec_helper'

RSpec.describe Poplidays::Validators::PropertyDetailsValidator do

  let(:invalid_details) do
    [
      {
        'requestOnly' => true,
        'priceEnabled' => true,
        'personMax' => 2,
        :_message => described_class::ON_REQUEST_MESSAGE
      }, # on requests property
      {
        'requestOnly' => false,
        'priceEnabled' => false,
        'personMax' => 2,
        :_message => described_class::PRICE_ENABLED_MESSAGE
      }, # price disabled property
      {
        'requestOnly' => false,
        'priceEnabled' => true,
        'personMax' => 0,
        :_message => described_class::INVALID_PERSON_MAX_MESSAGE
      } # max guests is 0
    ]
  end
  let(:valid_property) { { 'requestOnly' => false, 'priceEnabled' => true, 'personMax' => 2 } }

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on invalid property' do
      invalid_details.each do |details|
        validator = described_class.new(details)
        expect(validator.valid?).to be_falsey
        expect(validator.error).to eq details[:_message]
      end
    end
  end
end