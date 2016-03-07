require 'spec_helper'

RSpec.describe Jtb::Price do
  include Support::JtbClientHelper

  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, room_type_code: 'JPN' }
  }

  subject { described_class.new(params) }

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
        result = subject.quote(success_response)
        expect(result).to be_a Result
        expect(result).to be_success

        expect(result.value).to be_a Quotation
        expect(result.value).to be subject.quotation

        quotation = result.value
        expect(quotation).to be_successful
        expect(quotation.total).to eq 2000
        expect(quotation.available).to be true
      end
    end

    context 'fail' do
      let(:fail_response) {
        { ga_hotel_avail_rs: { error: 'Some error' } }
      }

      it 'returns quotation' do
        result = subject.quote(fail_response)
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :unavailable_property
      end

    end
  end

end