require 'spec_helper'
require_relative '../../support/helpers/jtb_client_helper'

RSpec.describe Jtb::Client do
  include JtbClientHelper

  before(:all) { savon.mock! }
  after(:all)  { savon.unmock! }

  let(:api) { double('Jtb::Api')}

  describe '#quote' do
    context 'success' do
      let(:success_response) do
        build_quote_response(
            [
                availability(price: '2000', date: '2016-10-10', status: 'OK', rate_plan_id: 'good rate'),
                availability(price: '1000', date: '2016-10-10', status: 'UC', rate_plan_id: 'abc'),
                availability(price: '4000', date: '2016-10-10', status: 'OK', rate_plan_id: 'expensive_rate'),
            ]
        )
      end

      before { allow(api).to receive(:quote_price).and_return(success_response) }

      it 'returns quotation with optimal price' do
        quotation = subject.quote({})
        expect(quotation).to be_a Quotation
        expect(quotation.total).to eq 2000
      end
    end

    context 'fail' do
      it 'returns quotation' do
        allow(api).to receive(:quote_price).and_return({})
        quotation = subject.quote({})
        expect(quotation.total).to be_nil
      end

    end
  end
end