require 'spec_helper'

RSpec.describe Ciirus::Commands::PropertyAvailableFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://proxy.roomorama.com/ciirus')
  end

  let(:params) do
    {
      property_id: 38180,
      check_in: '2016-05-01',
      check_out: '2016-05-12',
      guests: 3
    }
  end

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  let(:success_response) { read_fixture('ciirus/responses/is_property_available_response.xml') }

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

    it 'returns property availability' do
      stub_call(method: :is_property_available, response: success_response)

      result = subject.call(params)

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be false
    end
  end
end