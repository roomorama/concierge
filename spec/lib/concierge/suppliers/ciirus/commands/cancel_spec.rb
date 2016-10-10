require 'spec_helper'

RSpec.describe Ciirus::Commands::Cancel do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:reservation_id) { 134550 }

  let(:success_response) { read_fixture('ciirus/responses/cancel_response.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_cancel_response.xml') }
  let(:wsdl) { read_fixture('ciirus/additional_wsdl.xml') }

  subject { described_class.new(credentials) }

  describe '#call' do

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(reservation_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns success' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(reservation_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to eq(reservation_id)
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(reservation_id)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:soap_error)
        expect(result.error.data).to eq(
          "(soap:Server) Server was unable to process request. ---> You do not have access to this booking"
        )
      end
    end
  end
end
