require 'spec_helper'

RSpec.describe Ciirus::Commands::Booking do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:customer) do
    {
      first_name: 'John',
      last_name:  'Butler',
      email:      'john@email.com',
      phone:      '+3 5486 4560',
      address:    'Long Island 1245'
    }
  end

  let(:params) do
    API::Controllers::Params::Booking.new(
      property_id: 38180,
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end

  let(:success_response) { read_fixture('ciirus/responses/make_booking_response.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_make_booking_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  before do
    # Replace remote call for wsdl with static wsdl
    allow(subject).to receive(:options).and_wrap_original do |m, *args|
      original = m.call(*args)
      original[:wsdl] = wsdl
      original
    end
  end

  describe '#call' do

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(params)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success reservation' do
        stub_call(method: :make_booking, response: success_response)

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a ::Reservation
      end

      it 'fills reservation with right attributes' do
        stub_call(method: :make_booking, response: success_response)

        result = subject.call(params)

        reservation = result.value
        expect(reservation.check_in).to eq('2016-05-01')
        expect(reservation.check_out).to eq('2016-05-12')
        expect(reservation.guests).to eq(3)
        expect(reservation.property_id).to eq('38180')
        expect(reservation.code).to eq('873184')
        expect(reservation.customer).to eq(customer)
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: :make_booking, response: error_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)
      end
    end
  end
end