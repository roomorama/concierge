require 'spec_helper'

RSpec.describe Jtb::Client do
  include Support::JtbClientHelper

  let(:credentials) {
    { id: 'some id', user: 'Roberto', password: '123', company: 'Apple' }
  }
  subject { described_class.new(credentials) }

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

      it 'returns quotation with optimal price' do
        allow_any_instance_of(Jtb::Api).to receive(:quote_price) { success_response }
        quotation = subject.quote({})
        expect(quotation).to be_a Quotation
        expect(quotation.total).to eq 2000
      end
    end

    context 'fail' do
      let(:fail_response) {
        { ga_hotel_avail_rs: { error: 'Some error' } }
      }

      it 'returns quotation' do
        allow_any_instance_of(Jtb::Api).to receive(:quote_price) { fail_response }
        quotation = subject.quote({})
        expect(quotation).to_not be_successful
      end

    end
  end
end