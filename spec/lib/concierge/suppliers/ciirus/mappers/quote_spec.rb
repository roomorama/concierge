require 'spec_helper'

RSpec.describe Ciirus::Mappers::Quote do

  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 10,
                                        check_in: '2016-05-01',
                                        check_out: '2016-05-12',
                                        guests: 3)
  end

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

  it 'returns valid roomorama Quotation entity' do
    expect(quotation).to be_a(::Quotation)
  end

  it 'maps property_id attr' do
    expect(quotation.property_id).to eq('10')
  end

  it 'maps check_in attr' do
    expect(quotation.check_in).to eq('2016-05-01')
  end

  it 'maps check_out attr' do
    quotation = described_class.build(params, result_hash)
    expect(quotation.check_out).to eq('2016-05-12')
  end

  it 'maps guests attr' do
    expect(quotation.guests).to eq(3)
  end

  it 'maps total attr' do
    expect(quotation.total).to eq(3440.98)
  end

  it 'maps currency attr' do
    expect(quotation.currency).to eq('USD')
  end
end
