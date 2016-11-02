require 'spec_helper'

RSpec.describe Avantio::SoapClient do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:wsdl) { read_fixture('avantio/wsdl.xml') }
  let(:success_response) { read_fixture('avantio/get_booking_price_response.xml') }
  let(:method) { :get_booking_price }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(method, '')

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success result' do
        stub_call(method: method, response: success_response)

        result = subject.call(method, '')

        expect(result).to be_a Result
        expect(result).to be_success
      end
    end
  end
end