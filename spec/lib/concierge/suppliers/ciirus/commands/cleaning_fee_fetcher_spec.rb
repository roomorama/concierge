require 'spec_helper'

RSpec.describe Ciirus::Commands::CleaningFeeFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:property_id) { {property_id: '33680'} }

  let(:success_response) { read_fixture('ciirus/responses/cleaning_fee_response.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_cleaning_fee_response.xml') }
  let(:wsdl) { read_fixture('ciirus/additional_wsdl.xml') }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success property cleaning fee' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Ciirus::Entities::CleaningFee
      end

      it 'fills property cleaning fee with right attributes' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        cleaning_fee = result.value
        expect(cleaning_fee.charge_cleaning_fee).to be_truthy
        expect(cleaning_fee.amount).to eq(100)
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(property_id)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:not_empty_error_msg)
      end
    end
  end
end