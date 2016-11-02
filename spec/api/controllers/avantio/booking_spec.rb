require "spec_helper"
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::Avantio::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::SOAPStubbing

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

  let(:set_booking_response) { read_fixture('avantio/set_booking_response.xml') }
  let(:set_booking_error_response) { read_fixture('avantio/set_booking_error_response.xml') }
  let(:is_available_response) { read_fixture('avantio/is_available_response.xml') }
  let(:not_available_response) { read_fixture('avantio/not_available_response.xml') }
  let(:wsdl) { read_fixture('avantio/wsdl.xml') }

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }

  describe '#call' do

    it 'returns proper error if external request failed' do
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['booking']).to eq 'Could not create booking with remote supplier'
    end

    context 'when xml response is correct' do
      it 'fills reservation with right attributes' do
        stub_call(method: Avantio::Commands::IsAvailableFetcher::OPERATION_NAME,
                  response: is_available_response)
        stub_call(method: Avantio::Commands::SetBooking::OPERATION_NAME,
                  response: set_booking_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body['status']).to eq 'ok'
        expect(response.body['reference_number']).to eq '1491191'
        expect(response.body['property_id']).to eq '38180'
        expect(response.body['check_in']).to eq '2016-05-01'
        expect(response.body['check_out']).to eq '2016-05-12'
        expect(response.body['guests']).to eq 3
        expect(response.body['customer']).to eq customer
      end

      it 'returns error if property is not available' do
        stub_call(method: Avantio::Commands::IsAvailableFetcher::OPERATION_NAME,
                  response: not_available_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 503
        expect(response.body['status']).to eq 'error'
        expect(response.body['errors']['booking']).to eq 'The property user tried to book is unavailable for given period'
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: Avantio::Commands::IsAvailableFetcher::OPERATION_NAME,
                  response: is_available_response)
        stub_call(method: Avantio::Commands::SetBooking::OPERATION_NAME,
                  response: set_booking_error_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 503
        expect(response.body['status']).to eq 'error'
        expect(response.body['errors']['booking']).to eq (
          "The `set_booking` response contains unexpected data.\nSuccess: `false`\nErrorList: `ErrorId: 5005, ErrorMessage: Fallo al desbloquear el periodo de disponibilidad`"
        )
      end
    end
  end
end