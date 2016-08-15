require 'spec_helper'

RSpec.describe Ciirus::Validators::RateValidator do

  let(:invalid_rates) do
    [
      Ciirus::Entities::PropertyRate.new(
        Date.new(2014, 6, 18),
        Date.new(2014, 7, 10),
        4,
        190
      ), # too old
      Ciirus::Entities::PropertyRate.new(
        Date.new(2016, 6, 18),
        Date.new(2016, 7, 10),
        4,
        0
      ), # zero price
      Ciirus::Entities::PropertyRate.new(
        Date.new(2019, 6, 18),
        Date.new(2019, 7, 10),
        4,
        284
      ) # too far
    ]
  end
  let(:valid_rate) do
    Ciirus::Entities::PropertyRate.new(
      Date.new(2016, 6, 18),
      Date.new(2016, 7, 10),
      4,
      190
    )
  end
  let(:today) { Date.new(2016, 5, 30) }

  describe '#valid?' do
    it 'returns true for valid rate' do
      validator = described_class.new(valid_rate, today)
      expect(validator.valid?).to be_truthy
    end

    it 'returns false for invalid rates' do
      invalid_rates.each do |rate|
        validator = described_class.new(rate, today)
        expect(validator.valid?).to be_falsey
      end
    end
  end
end
