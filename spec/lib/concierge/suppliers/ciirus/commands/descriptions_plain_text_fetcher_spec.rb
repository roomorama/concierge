require 'spec_helper'

RSpec.describe Ciirus::Commands::DescriptionsPlainTextFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://proxy.roomorama.com/ciirus')
  end

  let(:property_id) { 38180 }

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  let(:success_response) { read_fixture('ciirus/descriptions_plain_text_response.xml') }
  let(:empty_response) { read_fixture('ciirus/empty_descriptions_plain_text_response.xml') }

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
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    it 'returns descriptions' do
      stub_call(method: :get_descriptions_plain_text, response: success_response)

      result = subject.call(property_id)

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to eq 'Some description here'
    end

    context 'when description is empty' do
      it 'returns empty string' do
        stub_call(method: :get_descriptions_plain_text, response: empty_response)

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_empty
      end
    end
  end
end