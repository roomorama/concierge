require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Avantio::Quote do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::SOAPStubbing
  include Support::Factories

  let!(:supplier) { create_supplier(name: Avantio::Client::SUPPLIER_NAME) }
  let!(:host) { create_host(fee_percentage: 7, supplier_id: supplier.id) }
  let!(:property) { create_property(identifier: '38180', host_id: host.id) }
  let(:params) {
    { property_id: property.identifier, check_in: '2016-05-01', check_out: '2016-05-12', guests: 3 }
  }

  let(:get_booking_price_response) { read_fixture('avantio/get_booking_price_response.xml') }
  let(:is_available_response) { read_fixture('avantio/is_available_response.xml') }
  let(:not_available_response) { read_fixture('avantio/not_available_response.xml') }

  let(:wsdl) { read_fixture('avantio/wsdl.xml') }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { Avantio::Client::SUPPLIER_NAME }

    def provoke_failure!
      allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
      Struct.new(:code).new("savon_error")
    end
  end

  describe '#call' do
    context 'when xml response is correct' do

      it 'fills quotation with right attributes' do
        stub_call(method: Avantio::Commands::IsAvailableFetcher::OPERATION_NAME,
                  response: is_available_response)
        stub_call(method: Avantio::Commands::QuoteFetcher::OPERATION_NAME,
                  response: get_booking_price_response)

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body['status']).to eq 'ok'
        expect(response.body['available']).to eq true
        expect(response.body['property_id']).to eq '38180'
        expect(response.body['check_in']).to eq '2016-05-01'
        expect(response.body['check_out']).to eq '2016-05-12'
        expect(response.body['guests']).to eq 3
        expect(response.body['currency']).to eq 'EUR'
        expect(response.body['total']).to eq 6805.0
      end

      it 'returns unavailable quotation for unavailable response' do
        stub_call(method: Avantio::Commands::IsAvailableFetcher::OPERATION_NAME,
                  response: not_available_response)

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
  end
end