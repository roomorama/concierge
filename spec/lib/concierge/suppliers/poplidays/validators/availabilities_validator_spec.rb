require 'spec_helper'

RSpec.describe Poplidays::Validators::AvailabilitiesValidator do

  let(:invalid_cases) do
    [
      {'availabilities' => []}, # empty
      {
        'availabilities' => [
          {'requestOnly' => true, 'priceEnabled' => true},
          {'requestOnly' => false, 'priceEnabled' => false}
        ]
      } # empty valid
    ]
  end
  let(:valid_case) do
    {
      'availabilities' => [
        {'requestOnly' => false, 'priceEnabled' => true}
      ]
    }
  end

  describe '#valid?' do
    it 'returns true for valid case' do
      validator = described_class.new(valid_case)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for on invalid cases' do
      invalid_cases.each do |c|
        validator = described_class.new(c)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end