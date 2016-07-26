require 'spec_helper'

RSpec.describe Ciirus::Mappers::SecurityDeposit do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_extras_response: {
            get_extras_result: {
              row_count: "2",
              extras: {
                property_extras: [
                  {
                    property_id: "33692",
                    item_code: "ADI",
                    item_description: "Accidental Damage Insurance",
                    flat_fee: false,
                    flat_fee_amount: "0",
                    daily_fee: false,
                    daily_fee_amount: "0",
                    percentage_fee: true,
                    percentage: "10.00",
                    mandatory: true,
                    minimum_charge: "14.00",
                    charge_tax1: true,
                    charge_tax2: true,
                    charge_tax3: true
                  },
                  {
                    property_id: "33692",
                    item_code: "SD",
                    item_description: "Security Deposit",
                    flat_fee: true,
                    flat_fee_amount: "2500.00",
                    daily_fee: false,
                    daily_fee_amount: "0",
                    percentage_fee: false,
                    percentage: "0",
                    mandatory: false,
                    minimum_charge: "0.00",
                    charge_tax1: true,
                    charge_tax2: true,
                    charge_tax3: true
                  }
                ]
              }
            },
            '@xmlns' => "http://xml.ciirus.com/"
          }
        }
      )
    end

    let(:result_hash_without_sd) do
      Concierge::SafeAccessHash.new(
        {
          get_extras_response: {
            get_extras_result: {
              row_count: "1",
              extras: {
                property_extras: [
                  {
                    property_id: "33692",
                    item_code: "ADI",
                    item_description: "Accidental Damage Insurance",
                    flat_fee: false,
                    flat_fee_amount: "0",
                    daily_fee: false,
                    daily_fee_amount: "0",
                    percentage_fee: true,
                    percentage: "10.00",
                    mandatory: true,
                    minimum_charge: "14.00",
                    charge_tax1: true,
                    charge_tax2: true,
                    charge_tax3: true
                  }
                ]
              }
            },
            '@xmlns' => "http://xml.ciirus.com/"
          }
        }
      )
    end


    subject { described_class.new }

    it 'returns mapped extra entity' do
      extra = subject.build(result_hash)
      expect(extra).to be_a(Ciirus::Entities::Extra)

      expect(extra.property_id).to eq('33692')
      expect(extra.item_code).to eq('SD')
      expect(extra.item_description).to eq('Security Deposit')
      expect(extra.flat_fee).to be_truthy
      expect(extra.flat_fee_amount).to eq(2500.0)
      expect(extra.daily_fee).to be_falsey
      expect(extra.daily_fee_amount).to eq(0)
      expect(extra.percentage_fee).to be_falsey
      expect(extra.percentage).to eq(0)
      expect(extra.mandatory).to be_falsey
      expect(extra.minimum_charge).to eq(0)
    end

    it 'returns nil for response without sd' do
      extra = subject.build(result_hash_without_sd)

      expect(extra).to be_nil
    end
  end

end
