require 'spec_helper'

RSpec.describe Avantio::Mappers::Quotation do

  let(:result_hash) do
    Concierge::SafeAccessHash.new({
      get_booking_price_rs: {
        booking_price: {
          room_only_final: '200.3',
          currency: 'EUR'
        }
      }
    })
  end

  context 'for valid result hash' do
    let(:quotation) { subject.build(result_hash) }

    subject { described_class.new }

    it 'returns Quotation entity' do
      expect(quotation).to be_a(Avantio::Entities::Quotation)
    end

    it 'returns mapped quotation entity' do
      expect(quotation.quote).to eq(200.3)
      expect(quotation.currency).to eq('EUR')
    end
  end
end
