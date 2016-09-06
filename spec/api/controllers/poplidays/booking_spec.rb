require "spec_helper"
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::Poplidays::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:customer) do
    {
      first_name:  'John',
      last_name:   'Buttler',
      address:     'Long Island 100',
      email:       'my@email.com',
      phone:       '+3 675 45879',
    }
  end

  let(:params) do
    {
      property_id: '38180',
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    2000,
      customer:    customer
    }
  end

  let(:success_response) do
    '{
      "id": 9257079406,
      "reference": "CHD00001",
      "ruid": "f211687c1e88e065e3331cacebe4803c"
    }'
  end
  let(:endpoint) { 'https://api.poplidays.com/v2/bookings/easy' }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

  describe '#call' do

    it 'returns proper error if external request failed' do
      stub_call(:post, endpoint) { Faraday::TimeoutError }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['booking']).to eq 'Could not create booking with remote supplier'
    end

    it 'fills reservation with right attributes when response is correct' do
      stub_call(:post, endpoint) { [200, {}, success_response] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['reference_number']).to eq '9257079406'
      expect(response.body['property_id']).to eq '38180'
      expect(response.body['check_in']).to eq '2016-05-01'
      expect(response.body['check_out']).to eq '2016-05-12'
      expect(response.body['guests']).to eq 3
      expect(response.body['customer']).to eq customer
    end

    it "returns an error with unrecognised response" do
      allow_any_instance_of(Poplidays::Client).to receive(:book) {
        Result.error(:unrecognised_response)
      }
      response = parse_response(subject.call(params))
      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]).to eq( { "booking" => "Could not create booking with remote supplier" })
    end
  end
end