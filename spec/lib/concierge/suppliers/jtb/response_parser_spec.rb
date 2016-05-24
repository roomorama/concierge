require 'spec_helper'

RSpec.describe JTB::ResponseParser do
  include Support::Fixtures
  include Support::JTBClientHelper

  subject { described_class.new }

  describe '#parse_rate_plan' do
    let(:params) {
      { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
    }

    context 'success' do
      let(:success_response) do
        build_quote_response(
          [
            availability(price: '2000', date: '2016-10-10', status: 'OK', occupancy: 2, rate_plan_id: 'good rate'),
            availability(price: '2100', date: '2016-10-11', status: 'OK', occupancy: 2, rate_plan_id: 'good rate'),
            availability(price: '1000', date: '2016-10-10', status: 'OK', occupancy: 1, rate_plan_id: 'small flat rate'),
            availability(price: '1100', date: '2016-10-11', status: 'OK', occupancy: 1, rate_plan_id: 'small flat rate'),
            availability(price: '1000', date: '2016-10-10', status: 'UC', occupancy: 2, rate_plan_id: 'abc'),
            availability(price: '1100', date: '2016-10-11', status: 'UC', occupancy: 2, rate_plan_id: 'abc'),
            availability(price: '4000', date: '2016-10-10', status: 'OK', occupancy: 2, rate_plan_id: 'expensive_rate'),
            availability(price: '4100', date: '2016-10-11', status: 'OK', occupancy: 2, rate_plan_id: 'expensive_rate'),
          ]
        )
      end
      let(:result) { subject.parse_rate_plan(success_response, params) }

      it 'is successful result' do
        expect(result).to be_a Result
        expect(result).to be_success
      end

      it 'has quotation value with best rate' do
        expect(result.value).to be_a JTB::RatePlan

        rate_plan = result.value
        expect(rate_plan.total).to eq 4100
        expect(rate_plan.rate_plan).to eq 'good rate'
        expect(rate_plan.available).to be_truthy
      end

    end

    it 'fails if invalid request' do
      response = parse read_fixture('jtb/invalid_request.json')
      result   = subject.parse_rate_plan(response, params)
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_request
    end

    it 'fails if unit not found' do
      response = parse read_fixture('jtb/unit_not_found.json')
      result   = subject.parse_rate_plan(response, params)
      expect(result).not_to be_success
      expect(result.error.code).to eq :unit_not_found
    end

    it 'recognises the response with single rate plan response' do
      response = parse(read_fixture("jtb/single_rate_plan_response.json"))
      result   = subject.parse_rate_plan(response, params)
      expect(result).to be_success
      expect(result.value).to be_a JTB::RatePlan
    end

  end

  private

  def parse(response)
    Yajl::Parser.parse(response, symbolize_keys: true)
  end
end
