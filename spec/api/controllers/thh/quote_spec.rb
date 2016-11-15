require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::THH::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  include Support::Factories

  let!(:supplier) { create_supplier(name: THH::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(supplier_id: supplier.id, fee_percentage: 5) }
  let!(:property) do
    create_property(
      identifier: '15',
      host_id: host.id,
      data: { max_guests: 2}
    )
  end
  let(:params) {
    { property_id: property.identifier, check_in: '2016-12-09', check_out: '2016-12-17', guests: 2 }
  }
  let(:url) { 'http://example.org' }
  let(:credentials) { double(key: 'Foo', url: url) }
  let(:quote_response) do
    Concierge::SafeAccessHash.new(
      {
        available: 'yes',
        price: '48,000'
      }
    )
  end
  let(:unavailable_quote_response) do
    Concierge::SafeAccessHash.new(
      {
        available: 'no',
        price: '48,000'
      }
    )
  end

  it_behaves_like 'performing parameter validations', controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like 'external error reporting' do
    let(:supplier_name) { THH::Client::SUPPLIER_NAME }

    def provoke_failure!
      stub_call(:get, url) { raise Faraday::TimeoutError }
      Struct.new(:code).new('connection_timeout')
    end
  end

  describe '#call' do
    it "returns a proper error if Price fails" do
      allow_any_instance_of(THH::Price).to receive(:quote) { Result.error(:error, 'Some error') }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body['status']).to eq 'error'
      expect(response.body['errors']['quote']).to eq 'Some error'
    end

    it 'returns unavailable quotation when the supplier responds so' do
      allow_any_instance_of(THH::Commands::QuoteFetcher).to receive(:call) { Result.new(unavailable_quote_response) }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['available']).to eq false
      expect(response.body['property_id']).to eq '15'
      expect(response.body['check_in']).to eq '2016-12-09'
      expect(response.body['check_out']).to eq '2016-12-17'
      expect(response.body['guests']).to eq 2
      expect(response.body).not_to have_key('currency')
      expect(response.body).not_to have_key('total')
    end

    it 'returns available quotations with price when the call is successful' do
      allow_any_instance_of(THH::Commands::QuoteFetcher).to receive(:call) { Result.new(quote_response) }


      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body['status']).to eq 'ok'
      expect(response.body['available']).to eq true
      expect(response.body['property_id']).to eq '15'
      expect(response.body['check_in']).to eq '2016-12-09'
      expect(response.body['check_out']).to eq '2016-12-17'
      expect(response.body['guests']).to eq 2
      expect(response.body['currency']).to eq 'THB'
      expect(response.body['total']).to eq 48000.0
    end

  end
end
