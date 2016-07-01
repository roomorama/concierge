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
    API::Controllers::Params::Quote.new(property_id: 38180,
                                        check_in: '2016-05-01',
                                        check_out: '2016-05-12',
                                        guests: 3)
  end

  let(:success_response) { read_fixture('ciirus/property_quote_response.xml') }
  let(:empty_response) { read_fixture('ciirus/empty_property_quote_response.xml') }
  let(:error_response) { read_fixture('ciirus/error_property_quote_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  before do
    # Replace remote call for wsdl with static wsdl
    allow(subject).to receive(:options).and_wrap_original do |m, *args|
      original = m.call
      original[:wsdl] = wsdl
      original
    end
  end

  describe '#call' do
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
        expect(quotation.check_in).to eq('2016-05-01')
        expect(quotation.check_out).to eq('2016-05-12')
        expect(quotation.guests).to eq(3)
        expect(quotation.property_id).to eq('38180')
        expect(quotation.currency).to eq('USD')
        expect(quotation.available).to be true
        expect(quotation.total).to eq(3440.98)
      end

      it 'returns unavailable quotation for empty response' do
        stub_call(method: :get_properties, response: empty_response)

        result = subject.call(params)

        quotation = result.value
        expect(quotation.check_in).to eq('2016-05-01')
        expect(quotation.check_out).to eq('2016-05-12')
        expect(quotation.guests).to eq(3)
        expect(quotation.property_id).to eq('38180')
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