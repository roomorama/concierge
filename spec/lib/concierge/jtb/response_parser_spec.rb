require 'spec_helper'

RSpec.describe JTB::ResponseParser do
  include Support::Fixtures
  include Support::JTBClientHelper

  subject { described_class.new }

  describe '#parse_quote' do
    let(:params) {
      { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
    }

    context 'success' do
      let(:success_response) do
        build_quote_response(
          [
            availability(price: '2000', date: '2016-10-10', status: 'OK', rate_plan_id: 'good rate'),
            availability(price: '2100', date: '2016-10-11', status: 'OK', rate_plan_id: 'good rate'),
            availability(price: '1000', date: '2016-10-10', status: 'UC', rate_plan_id: 'abc'),
            availability(price: '1100', date: '2016-10-11', status: 'UC', rate_plan_id: 'abc'),
            availability(price: '4000', date: '2016-10-10', status: 'OK', rate_plan_id: 'expensive_rate'),
            availability(price: '4100', date: '2016-10-11', status: 'OK', rate_plan_id: 'expensive_rate'),
          ]
        )
      end
      let(:result) { subject.parse_quote(success_response, params) }

      it 'is successful result' do
        expect(result).to be_a Result
        expect(result).to be_success
      end

      it 'has quotation value with best rate' do
        expect(result.value).to be_a Quotation

        quotation = result.value
        expect(quotation.total).to eq 4100
        expect(quotation.currency).to eq 'JPY'
        expect(quotation.available).to be_truthy
      end

    end

    it 'fails if invalid request' do
      response = parse read_fixture('jtb/invalid_request.json')
      result   = subject.parse_quote(response, params)
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_request
    end

    it 'fails if unit not found' do
      response = parse read_fixture('jtb/unit_not_found.json')
      result   = subject.parse_quote(response, params)
      expect(result).not_to be_success
      expect(result.error.code).to eq :unit_not_found
    end

  end

  private

  def parse(response)
    Yajl::Parser.parse(response, symbolize_keys: true)
  end
end