require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Poplidays::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  include Support::Factories

  let!(:supplier) { create_supplier(name: Poplidays::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(supplier_id: supplier.id, fee_percentage: 5) }
  let!(:property) { create_property(identifier: '48327', host_id: host.id) }
  let(:params) {
    { property_id: property.identifier, check_in: '2016-12-17', check_out: '2016-12-26', guests: 2 }
  }
  let(:credentials) do
    double(url: 'api.poplidays.com',
           client_key: '1111',
           passphrase: '4311')
  end
  let(:success_quote_response) do
    '{
      "value": 3410.28,
      "ruid": "09cdecc64b5ba9504c08bb598075262f"
    }'
  end
  let(:unavailable_quote_response) do
    '{
      "code": 400,
      "message": "Unauthorized arriving day",
      "ruid": "76b95928b4fec0ca2dc6ddb33e89b044"
    }'
  end
  let(:property_details_endpoint) { 'https://api.poplidays.com/v2/lodgings/48327' }
  let(:quote_endpoint) { 'https://api.poplidays.com/v2/bookings/easy' }

  it_behaves_like 'performing parameter validations', controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like 'external error reporting' do
    let(:supplier_name) { 'Poplidays' }

    def provoke_failure!
      stub_call(:get, property_details_endpoint) { raise Faraday::TimeoutError }
      Struct.new(:code).new('connection_timeout')
    end
  end

  describe '#call' do
    it "returns a proper error message if the response contains missing mandatory services" do
      fixture = 'poplidays/property_details_missing_mandatory_services.json'
      stub_call(:get, property_details_endpoint) { [200, {}, read_fixture(fixture)] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['quote']).to eq 'Expected to find the price for mandatory services under the `mandatoryServicesPrice`, but none was found.'
    end

    it "returns a proper error message if the response contains unexpected xml response" do
      fixture = 'poplidays/unexpected_xml_response.xml'
      stub_call(:get, property_details_endpoint) { [200, {}, read_fixture(fixture)] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['quote']).to eq 'Could not quote price with remote supplier'
    end

    it 'returns unavailable quotation when the supplier responds so' do
      stub_call(:get, property_details_endpoint) { [200, {}, read_fixture('poplidays/property_details.json')] }
      stub_call(:post, quote_endpoint) { [400, {}, unavailable_quote_response] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['available']).to eq false
      expect(response.body['property_id']).to eq '48327'
      expect(response.body['check_in']).to eq '2016-12-17'
      expect(response.body['check_out']).to eq '2016-12-26'
      expect(response.body['guests']).to eq 2
      expect(response.body).not_to have_key('currency')
      expect(response.body).not_to have_key('total')
    end

    it 'returns available quotations with price when the call is successful' do
      stub_call(:post, quote_endpoint) { [200, {}, success_quote_response] }
      stub_call(:get, property_details_endpoint) { [200, {}, read_fixture('poplidays/property_details.json')] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['available']).to eq true
      expect(response.body['property_id']).to eq '48327'
      expect(response.body['check_in']).to eq '2016-12-17'
      expect(response.body['check_out']).to eq '2016-12-26'
      expect(response.body['guests']).to eq 2
      expect(response.body['currency']).to eq 'EUR'
      expect(response.body['total']).to eq 3410.28 + 25 # rental + mandatory services
    end

  end
end
