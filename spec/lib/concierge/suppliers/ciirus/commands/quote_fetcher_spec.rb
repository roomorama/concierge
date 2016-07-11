require 'spec_helper'

RSpec.describe Ciirus::Commands::QuoteFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 33680,
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end

  let(:success_response) { read_fixture('ciirus/responses/property_quote_response.xml') }
  let(:empty_response) { read_fixture('ciirus/responses/empty_property_quote_response.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_property_quote_response.xml') }
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
      it 'returns success quotation' do
        stub_call(method: :get_properties, response: success_response)

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Quotation
      end

      it 'fills quotation with right attributes' do
        stub_call(method: :get_properties, response: success_response)

        result = subject.call(params)

        quotation = result.value
        expect(quotation.check_in).to eq('2017-08-01')
        expect(quotation.check_out).to eq('2017-08-05')
        expect(quotation.guests).to eq(2)
        expect(quotation.property_id).to eq('33680')
        expect(quotation.currency).to eq('USD')
        expect(quotation.available).to be true
        expect(quotation.total).to eq(698.19)
      end

      it 'returns unavailable quotation for appropriate response' do
        stub_call(method: :get_properties, response: empty_response)

        result = subject.call(params)

        quotation = result.value
        expect(quotation.check_in).to eq('2017-08-01')
        expect(quotation.check_out).to eq('2017-08-05')
        expect(quotation.guests).to eq(2)
        expect(quotation.property_id).to eq('33680')
        expect(quotation.available).to be false
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: :get_properties, response: error_response)

        result = subject.call(params)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:not_empty_error_msg)
      end
    end
  end
end