require 'spec_helper'

RSpec.describe Ciirus::Mappers::PropertyRate do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          from_date: DateTime.new(2014, 6, 27),
          to_date: DateTime.new(2014, 8, 22),
          min_nights_stay: '3',
          daily_rate: '157.50'
        }
      )
    end

    it 'returns mapped property rate entity' do
      mapped_rate = described_class.build(result_hash)
      expect(mapped_rate).to be_a(Ciirus::Entities::PropertyRate)
      expect(mapped_rate.from_date).to eq(DateTime.new(2014, 6, 27))
      expect(mapped_rate.to_date).to eq(DateTime.new(2014, 8, 22))
      expect(mapped_rate.min_nights_stay).to eq(3)
      expect(mapped_rate.daily_rate).to eq(157.5)
    end
  end

end
