require 'spec_helper'
require 'savon/mock/spec_helper'

RSpec.describe API::Support::SOAPClient do
  include Savon::SpecHelper
  include Support::Fixtures

  describe '#call' do

    before(:all) { savon.mock! }
    after(:all) { savon.unmock! }

    let(:endpoint) { 'https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelAvail_v2013' }
    let(:operation) { :gby010 }
    let(:succeed_response) { read_fixture('jtb/GA_HotelAvailRS.xml') }
    subject { described_class.new(options(endpoint)) }

    it 'returns result' do
      allow(HTTPI).to receive(:get) { HTTPI::Response.new(200, {}, read_fixture('jtb/wsdl_response.xml')) }

      savon.expects(operation).with(message: :any).returns(succeed_response)
      result = subject.call(operation)
      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to be_a Hash
    end

    it "announces request and response" do
      allow(HTTPI).to receive(:get) { HTTPI::Response.new(200, {}, read_fixture('jtb/wsdl_response.xml')) }

      request  = Struct.new(:endpoint, :operation, :message).new
      response = Struct.new(:code, :headers, :body).new

      Concierge::Announcer.on(API::Support::SOAPClient::ON_REQUEST) do |endpoint, operation, message|
        request.endpoint  = endpoint
        request.operation = operation
        request.message   = message
      end

      Concierge::Announcer.on(API::Support::SOAPClient::ON_RESPONSE) do |code, headers, body|
        response.code    = code
        response.headers = headers
        response.body    = body
      end

      savon.expects(operation).with(message: :any).returns(succeed_response)
      subject.call(operation, message: "<concierge>true</concierge>")

      expect(request.endpoint).to eq "https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelAvail_v2013"
      expect(request.operation).to eq :gby010
      expect(request.message).to eq "<concierge>true</concierge>"

      expect(response.code).to eq 200
      expect(response.headers).to eq({})
      expect(response.body).to eq read_fixture("jtb/GA_HotelAvailRS.xml")
    end

    context 'handling errors' do

      it 'fails if wrong operation name' do
        allow(HTTPI).to receive(:get) { HTTPI::Response.new(200, {}, "<concierge>true</concierge>") }

        operation = :wrong_name
        result    = subject.call(operation)
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :unknown_operation
      end

      context 'wrong endpoint' do
        let(:wrong_endpoint) { 'https://trial-www.jtbgenesis.com/genesis2-demo/services/SomeMistake' }
        subject { described_class.new(options(wrong_endpoint)) }

        before { allow(HTTPI).to receive(:get) { HTTPI::Response.new(404, {}, []) } }

        it 'returns result with 404 http error' do

          result = subject.call(operation)
          expect(result).to be_a Result
          expect(result).not_to be_success
          expect(result.error.code).to eq 'http_status_404'
        end

        it "announces the error" do
          error = Struct.new(:message, :backtrace).new

          Concierge::Announcer.on(API::Support::SOAPClient::ON_FAILURE) do |message, backtrace|
            error.message   = message
            error.backtrace = backtrace
          end

          subject.call(operation)
          expect(error.message).to match %r[HTTP error \(404\)]
          expect(error.backtrace).to be_a Array
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
