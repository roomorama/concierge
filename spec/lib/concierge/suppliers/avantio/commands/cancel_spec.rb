require 'spec_helper'

RSpec.describe Avantio::Commands::Cancel do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123')
  end

  let(:booking_code) { 134550 }

  let(:success_response) { read_fixture('avantio/cancel_response.xml') }
  let(:errors_response) { read_fixture('avantio/errors_cancel_response.xml') }
  let(:error_response) { read_fixture('avantio/error_cancel_response.xml') }
  let(:unexpected_response) { read_fixture('avantio/unexpected_response.xml') }
  let(:wsdl) { read_fixture('avantio/wsdl.xml') }

  subject { described_class.new(credentials) }

  describe '#call' do

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(booking_code)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(booking_code)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to eq(booking_code)
      end
    end

    context 'when response contains errors' do
      it 'augment context with parsed errors' do
        stub_call(method: described_class::OPERATION_NAME, response: errors_response)

        result = subject.call(booking_code)

        message = "The `cancel_booking` response contains unexpected data.\nSucceed: `false`\nErrorList: `ErrorId: 303, ErrorMessage: \n"\
          "ErrorId: 5005, ErrorMessage: Fallo al desbloquear el periodo de disponibilidad`"
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)
        expect(result.error.data).to eq(message)

        event = Concierge.context.events_tracker.events.last
        expect(event).not_to be_nil
        expect(event.message.message).to eq(message)
      end

      it 'augment context with parsed error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(booking_code)

        message = "The `cancel_booking` response contains unexpected data.\nSucceed: `false`\nErrorList: `ErrorId: 5005, ErrorMessage: Fallo al desbloquear el periodo de disponibilidad`"
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)
        expect(result.error.data).to eq(message)

        event = Concierge.context.events_tracker.events.last
        expect(event).not_to be_nil
        expect(event.message.message).to eq(message)
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: unexpected_response)

        result = subject.call(booking_code)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response)
        expect(result.error.data).to eq('The `cancel_booking` response contains unexpected data.')
      end
    end
  end
end