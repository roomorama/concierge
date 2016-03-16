require 'spec_helper'

RSpec.describe JTB::Price do
  include Support::Fixtures
  include Support::JTBClientHelper

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple', url: 'https://trial-www.jtbgenesis.com/genesis2-demo/services') }
  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'JPN' }
  }
  let(:success_response) { parse_response('jtb/success_quote_response.json') }
  let(:fail_response) { parse_response('jtb/invalid_request.json') }


  subject { described_class.new(credentials) }

  describe '#best_rate_plan' do

    it 'returns quotation with optimal price' do
      allow(subject).to receive(:remote_call) { Result.new(success_response) }

      result = subject.best_rate_plan(params)
      expect(result).to be_a Result
      expect(result).to be_success

      expect(result.value).to be_a JTB::RatePlan
    end

    it 'fails if gets bad response' do
      allow(subject).to receive(:remote_call) { Result.new(fail_response) }

      result = subject.best_rate_plan(params)
      expect(result).to be_a Result
      expect(result).not_to be_success
    end

  end

  describe '#quote' do
    let(:rate_plan) { JTB::RatePlan.new('test', 1000, true) }

    it 'returns quotation with rate plan total' do
      allow(subject).to receive(:best_rate_plan) { Result.new(rate_plan) }

      result = subject.quote(params)
      expect(result).to be_a Result
      expect(result).to be_success

      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.total).to eq 1000
      expect(quotation.currency).to eq 'JPY'
    end

    it 'fails if gets bad response' do
      allow(subject).to receive(:best_rate_plan) { Result.error(:some_error, 'Message') }

      result = subject.best_rate_plan(params)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :some_error
    end


  end

  private

  def parse_response(fixture_path)
    Yajl::Parser.parse read_fixture(fixture_path), symbolize_keys: true
  end
end
