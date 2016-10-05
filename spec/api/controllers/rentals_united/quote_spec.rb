require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::RentalsUnited::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Factories

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }

  before do
    supplier = create_supplier(name: supplier_name)
    host = create_host(identifier: "ru-host", supplier_id: supplier.id)
    create_property(
      identifier: "321",
      host_id: host.id,
      data: { :currency => "USD" }
    )
  end

  let(:params) do
    {
      property_id: "321",
      check_in: "2016-03-22",
      check_out: "2016-03-25",
      guests: 2
    }
  end

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    def provoke_failure!
      stub_call(:post, credentials.url) do
        raise Faraday::TimeoutError
      end
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    context "when params are valid" do
      let(:params) do
        {
          property_id: "321",
          check_in: "2016-03-22",
          check_out: "2016-03-25",
          guests: 2
        }
      end

      it "respond with successfull response" do
        stub_data = read_fixture("rentals_united/quotations/success.xml")
        stub_call(:post, credentials.url) { [200, {}, stub_data] }

        response = parse_response(subject.call(params))
        expect(response.status).to eq 200
        expect(response.body['status']).to eq("ok")
        expect(response.body['available']).to be true
        expect(response.body['property_id']).to eq("321")
        expect(response.body['check_in']).to eq("2016-03-22")
        expect(response.body['check_out']).to eq("2016-03-25")
        expect(response.body['guests']).to eq(2)
        expect(response.body['currency']).to eq("USD")
        expect(response.body['total']).to eq(284.5)
        expect(response.body['net_rate']).to eq(284.5)
        expect(response.body['host_fee']).to eq(0.0)
        expect(response.body['host_fee_percentage']).to eq(0.0)
      end

      it "respond with successfull response but unavailable quotation" do
        stub_data = read_fixture("rentals_united/quotations/not_available.xml")
        stub_call(:post, credentials.url) { [200, {}, stub_data] }

        response = parse_response(subject.call(params))
        expect(response.status).to eq 200
        expect(response.body['status']).to eq("ok")
        expect(response.body['available']).to be false
        expect(response.body['property_id']).to eq("321")
        expect(response.body['check_in']).to eq("2016-03-22")
        expect(response.body['check_out']).to eq("2016-03-25")
        expect(response.body['guests']).to eq(2)
        expect(response.body['currency']).to eq(nil)
        expect(response.body['total']).to eq(nil)
        expect(response.body['net_rate']).to eq(nil)
        expect(response.body['host_fee']).to eq(nil)
        expect(response.body['host_fee_percentage']).to eq(nil)
      end
    end
  end
end

