require 'spec_helper'

RSpec.describe Ciirus::Mappers::CleaningFee do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_cleaning_fee_response: {
            get_cleaning_fee_result: {
              charge_cleaning_fee: true,
              cleaning_fee_amount: '100',
              only_charge_cleaning_fee_when_less_than_days: '99',
              charge_tax1: true,
              charge_tax2: true,
              charge_tax3: true
            },
            '@xmlns' => 'http://xml.ciirus.com/'
          }
        }
      )
    end

    subject { described_class.new }

    it 'returns mapped property cleaning fee entity' do
      cleaning_fee = subject.build(result_hash)
      expect(cleaning_fee).to be_a(Ciirus::Entities::CleaningFee)
      expect(cleaning_fee.charge_cleaning_fee).to be_truthy
      expect(cleaning_fee.amount).to eq(100)
    end
  end

end
