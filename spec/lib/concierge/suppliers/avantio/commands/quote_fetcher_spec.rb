require 'spec_helper'

RSpec.describe Avantio::Commands::QuoteFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123')
  end

  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 33680,
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end

  let(:success_response) { read_fixture('avantio/get_booking_price_response.xml') }
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
      it 'returns success quotation' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Avantio::Entities::Quotation
      end

      it 'fills quotation with right attributes' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(params)

        quotation = result.value
        expect(quotation.quote).to eq(6805)
        expect(quotation.currency).to eq('EUR')
      end
    end

    context 'when response with unexpected structure' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: unexpected_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:unexpected_response_structure)
      end
    end
  end
end