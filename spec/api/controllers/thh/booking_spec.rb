require "spec_helper"
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::THH::Booking do
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
      property_id: '15',
      check_in:    '2016-12-09',
      check_out:   '2016-12-17',
      guests:      3,
      subtotal:    2000,
      customer:    customer
    }
  end
  let(:credentials) { double(key: 'Foo', url: url) }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

  describe '#call' do

    it 'returns proper error if external request failed' do
      allow_any_instance_of(THH::Booking).to receive(:book) { Result.error(:some_error, 'Some error') }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['booking']).to eq 'Some error'
    end

    it 'fills reservation with right attributes when response is correct' do
      reservation = Reservation.new(params)
      reservation.reference_number = 'test_code'
      allow_any_instance_of(THH::Booking).to receive(:book) { Result.new(reservation) }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['reference_number']).to eq 'test_code'
      expect(response.body['property_id']).to eq '15'
      expect(response.body['check_in']).to eq '2016-12-09'
      expect(response.body['check_out']).to eq '2016-12-17'
      expect(response.body['guests']).to eq 3
      expect(response.body['customer']).to eq customer
    end
  end
end