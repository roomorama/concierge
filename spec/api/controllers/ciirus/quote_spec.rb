require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Ciirus::Quote do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::SOAPStubbing

  let(:params) {
    { property_id: '38180', check_in: '2016-05-01', check_out: '2016-05-12', guests: 3 }
  }

  let(:success_response) { read_fixture('ciirus/property_quote_response.xml') }
  let(:empty_response) { read_fixture('ciirus/empty_property_quote_response.xml') }
  let(:error_response) { read_fixture('ciirus/error_property_quote_response.xml') }

  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  before do
    # Replace remote call for wsdl with static wsdl
    allow_any_instance_of(Ciirus::Commands::QuoteFetcher).to receive(:options).and_wrap_original do |m, *args|
      original = m.call
      original[:wsdl] = wsdl
      original
    end
  end

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { Ciirus::Client::SUPPLIER_NAME }

    def provoke_failure!
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
      Struct.new(:code).new("savon_error")
    end
  end

  describe '#call' do
    context 'when xml response is correct' do

      it 'fills quotation with right attributes' do
        stub_call(method: :get_properties, response: success_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body['status']).to eq 'ok'
        expect(response.body['available']).to eq true
        expect(response.body['property_id']).to eq '38180'
        expect(response.body['check_in']).to eq '2016-05-01'
        expect(response.body['check_out']).to eq '2016-05-12'
        expect(response.body['guests']).to eq 3
        expect(response.body['currency']).to eq 'USD'
        expect(response.body['total']).to eq 3440.98
      end

      it 'returns unavailable quotation for empty response' do
        stub_call(method: :get_properties, response: empty_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body['status']).to eq 'ok'
        expect(response.body['available']).to eq false
        expect(response.body['property_id']).to eq '38180'
        expect(response.body['check_in']).to eq '2016-05-01'
        expect(response.body['check_out']).to eq '2016-05-12'
        expect(response.body['guests']).to eq 3
        expect(response.body).not_to have_key('currency')
        expect(response.body).not_to have_key('total')
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: :get_properties, response: error_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 503
        expect(response.body['status']).to eq 'error'
        expect(response.body['errors']['quote']).to eq 'Could not quote price with remote supplier'
      end
    end
  end
end