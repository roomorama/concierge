require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe API::Support::SOAPClient do
  include Savon::SpecHelper
  include Support::Fixtures

  describe '#call' do

    before(:all) { savon.mock! }
    after(:all) { savon.unmock! }

    # Have to set real endpoint, Savon sends request to check operations
    let(:endpoint) { 'https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelAvail_v2013' }
    let(:operation) { :gby010 }
    let(:succeed_response) { read_fixture('jtb/GA_HotelAvailRS.xml') }
    subject { described_class.new(options(endpoint)) }

    it 'returns result' do
      savon.expects(operation).with(message: :any).returns(succeed_response)
      result = subject.call(operation)
      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be_a Hash
    end

    context 'handling errors' do

      it 'fails if wrong operation name' do
        operation = :wrong_name
        result    = subject.call(operation)
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :unknown_operation
      end

      context 'wrong endpoint' do
        let(:wrong_endpoint) { 'https://trial-www.jtbgenesis.com/genesis2-demo/services/SomeMistake' }
        subject { described_class.new(options(wrong_endpoint)) }

        it 'returns result with 404 http error' do
          result = subject.call(operation)
          expect(result).to be_a Result
          expect(result).not_to be_success
          expect(result.error.code).to eq 'http_status_404'
        end
      end

    end
  end

  private

  def options(endpoint)
    {
        wsdl:                 endpoint + '?wsdl',
        env_namespace:        :soapenv,
        namespace_identifier: 'some namespace',
        endpoint:             endpoint
    }

  end
end
