require 'spec_helper'

RSpec.describe JTB::Booking do
  include Support::Fixtures
  include Support::JTBClientHelper

  let(:credentials) { double(id: 'some id', user: 'Roberto', password: '123', company: 'Apple', url: 'https://trial-www.jtbgenesis.com/genesis2-demo/services') }
  let(:params) {
    {
      property_id: 'A123',
      unit_id:     'JPN',
      check_in:    '2016-03-22',
      check_out:   '2016-03-24',
      guests:      2,
      customer:    {
        first_name:  'Alex',
        last_name:   'Black',
        gender:      'male'
      }
    }
  }
  subject { described_class.new(credentials) }

  describe '#booking' do
    let(:success_response) { parse_response('jtb/success_booking_response.json') }
    let(:rate_plan) { JTB::RatePlan.new('some rate') }

    it 'returns reservation' do
      allow_any_instance_of(JTB::Price).to receive(:best_rate_plan) { Result.new(rate_plan) }
      allow(subject).to receive(:remote_call) { Result.new(success_response) }

      result = subject.book(params)
      expect(result).to be_a Result
      expect(result).to be_success

      expect(result.value).to be_a String
      expect(result.value).to eq 'XXXXXXXXXX'
    end

    let(:fail_response) { parse_response('jtb/invalid_request.json') }

    it 'fails with bad response' do
      allow(subject).to receive(:remote_call) { Result.new(fail_response) }

      result = subject.book(params)
      expect(result).to be_a Result
      expect(result).not_to be_success
    end

  end

  private

  def parse_response(fixture_path)
    Yajl::Parser.parse read_fixture(fixture_path), symbolize_keys: true
  end
end
