require 'spec_helper'

RSpec.describe JTB::Price do
  include Support::Fixtures
  include Support::JTBClientHelper

  let(:credentials) do
    double(
      api: {
        'id' => 'some id',
        'user' => 'Roberto',
        'password' => '123',
        'company' => 'Apple',
        'url' => 'https://trial-www.jtbgenesis.com/genesis2-demo/services'
      }
    )
  end
  let(:params) {
    { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2, unit_id: 'TWN|CHUHW01RM0000001' }
  }
  let(:success_response) { parse_response('jtb/success_quote_response.json') }
  let(:fail_response) { parse_response('jtb/invalid_request.json') }


  subject { described_class.new(credentials) }

  describe '#best_rate_plan' do

    it 'returns quotation with optimal price' do
      allow(subject).to receive(:remote_call) { Result.new(success_response) }
      allow(subject).to receive(:rate_plans_ids) { ['TYOHKPT00STD1TWN'] }

      result = subject.best_rate_plan(params)

      expect(result).to be_a Result
      expect(result).to be_success

      expect(result.value).to be_a JTB::RatePlan
      expect(result.value.rate_plan).to eq('TYOHKPT00STD1TWN')
      expect(result.value.total).to eq(20700)
      expect(result.value.available).to be true
      expect(result.value.occupancy).to eq(2)
    end

    it 'caches result for the same call' do
      allow(subject).to receive(:remote_call) { Result.new(success_response) }

      expect{ subject.best_rate_plan(params) }.to change { Concierge::Cache::EntryRepository.count }

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

    it 'returns unavailable quotation when unavailable rate plan' do
      allow(subject).to receive(:best_rate_plan) { Result.new(JTB::RatePlan.new) }

      result = subject.quote(params)
      expect(result).to be_success

      quotation = result.value
      expect(quotation).to be_a Quotation
      expect(quotation.available).to be false
    end

    it 'fails if gets bad response' do
      allow(subject).to receive(:best_rate_plan) { Result.error(:some_error) }

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
