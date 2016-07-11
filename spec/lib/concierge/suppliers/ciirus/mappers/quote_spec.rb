require 'spec_helper'

RSpec.describe Ciirus::Mappers::Quote do

  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 10,
                                        check_in: '2016-05-01',
                                        check_out: '2016-05-12',
                                        guests: 3)
  end

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_properties_response: {
            get_properties_result: {
              property_details: {
                quote_excluding_tax: '3072.30',
                quote_including_tax: '3440.98',
                currency_code: 'USD'
              }
            }
          }
        }
      )
    end

    let(:quotation) { described_class.build(params, result_hash) }

    it 'returns roomorama Quotation entity' do
      expect(quotation).to be_a(::Quotation)
    end

    it 'returns mapped roomorama quotation entity' do
      expect(quotation).to be_a(::Quotation)
      expect(quotation.check_in).to eq('2016-05-01')
      expect(quotation.property_id).to eq('10')
      expect(quotation.check_out).to eq('2016-05-12')
      expect(quotation.guests).to eq(3)
      expect(quotation.total).to eq(3440.98)
      expect(quotation.currency).to eq('USD')
      expect(quotation.available).to be true
    end
  end

  context 'for empty result hash' do
    let(:empty_result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_properties_response: {
            get_properties_result: {
              property_details: {
                error_msg: 'No Properties were found that fit the specified search Criteria.'
              }
            }
          }
        }
      )
    end

    it 'returns unavailable quotation' do
      quotation = described_class.build(params, empty_result_hash)

      expect(quotation.available).to be false
    end
  end
end
