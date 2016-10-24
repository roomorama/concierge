require 'spec_helper'

RSpec.describe JTB::Cancel do
  include Support::Fixtures
  include Support::Factories

  let(:reference_number) { 'reservation_id|rate_plan_id' }
  before do
    create_reservation({ supplier: JTB::Client::SUPPLIER_NAME,
                         reference_number: reference_number })
  end

  let(:credentials) do
    double(
      api: {
        'id' => 'some id',
        'user' => 'Roberto',
        'password' => '123',
        'company' => 'Apple',
        'url' => 'https://trial-www.jtbgenesis.com/genesis2-demo/services',
        'test' => true
      }
    )
  end
  let(:params) {
    {
      reference_number: reference_number,
      inquiry_id:       '123'
    }
  }
  subject { described_class.new(credentials) }

  describe '#cancel' do

    it 'returns error if reservation not found' do
      result = subject.cancel(params.merge({ reference_number: 'foo|bar' }))

      expect(result).to be_a(Result)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:reservation_not_found)
      expect(result.error.data).to eq("Reservation with reference number `foo|bar` not found")
    end

    let(:fail_response) { parse_response('jtb/invalid_cancel_request.json') }

    it 'fails with bad response' do
      allow(subject).to receive(:remote_call) { Result.new(fail_response) }

      result = subject.cancel(params)
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq(:request_error)
      expect(result.error.data).to eq("The response indicated errors while processing the request. Check the `errors` field.")
    end

    let(:success_response) { parse_response('jtb/success_cancel_response.json') }

    xit 'returns reservation' do
      allow(subject).to receive(:remote_call) { Result.new(success_response) }

      result = subject.book(params)
      expect(result).to be_a Result
      expect(result).to be_success

      expect(result.value).to be_a String
      expect(result.value).to eq 'XXXXXXXXXX|some rate'
    end
  end

  private

  def parse_response(fixture_path)
    Yajl::Parser.parse read_fixture(fixture_path), symbolize_keys: true
  end
end
