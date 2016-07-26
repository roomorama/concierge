require 'spec_helper'

RSpec.describe Poplidays::Validators::PropertyDetailsValidator do

  let(:invalid_details) do
    [
      {'requestOnly' => true, 'priceEnabled' => true}, # on requests property
      {'requestOnly' => false, 'priceEnabled' => false} # price disabled property
    ]
  end
  let(:valid_property) { {'requestOnly' => false, 'priceEnabled' => true} }

  describe '#valid?' do
    it 'returns true for valid property' do
      validator = described_class.new(valid_property)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on invalid property' do
      invalid_details.each do |details|
        validator = described_class.new(details)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end