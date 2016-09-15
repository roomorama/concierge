require 'spec_helper'

RSpec.describe Avantio::Commands::SetBooking do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo', password: '123', test: true)
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
      property_id: '38180',
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end

  let(:success_response) { read_fixture('avantio/set_booking_response.xml') }
  let(:error_response) { read_fixture('avantio/set_booking_error_response.xml') }
  let(:errors_response) { read_fixture('avantio/set_booking_errors_response.xml') }
  let(:unexpected_response) { read_fixture('avantio/unexpected_response.xml') }
  let(:wsdl) { read_fixture('avantio/wsdl.xml') }

  subject { described_class.new(credentials) }

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
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a ::Reservation
      end

      it 'fills reservation with right attributes' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(params)

        reservation = result.value
        expect(reservation.check_in).to eq('2016-05-01')
        expect(reservation.check_out).to eq('2016-05-12')
        expect(reservation.guests).to eq(3)
        expect(reservation.property_id).to eq('38180')
        expect(reservation.reference_number).to eq('1491191')
        expect(reservation.customer).to eq(customer)
      end
    end

    context 'when response contains errors' do
      it 'augment context with parsed errors' do
        stub_call(method: described_class::OPERATION_NAME, response: errors_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)

        event = Concierge.context.events_tracker.events.last
        expect(event).not_to be_nil
        expect(event.message.message).to eq(
          "The response contains unexpected data:\nSuccess: `false`\nErrorList: `ErrorId: 303, ErrorMessage: \n"\
          "ErrorId: 5005, ErrorMessage: Fallo al desbloquear el periodo de disponibilidad`"
        )
      end

      it 'augment context with parsed error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)

        event = Concierge.context.events_tracker.events.last
        expect(event).not_to be_nil
        expect(event.message.message).to eq(
          "The response contains unexpected data:\nSuccess: `false`\nErrorList: `ErrorId: 5005, ErrorMessage: Fallo al desbloquear el periodo de disponibilidad`"
        )
      end
    end

    context 'when response with unexpected structure' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: unexpected_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)
      end
    end
  end
end