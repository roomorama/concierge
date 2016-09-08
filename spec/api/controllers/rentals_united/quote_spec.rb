require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::RentalsUnited::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

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
    let(:supplier_name) { "rentals_united" }
    let(:credentials) { Concierge::Credentials.for(supplier_name) }

    def provoke_failure!
      stub_call(:post, credentials.url) do
        raise Faraday::TimeoutError
      end
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    let(:credentials) { Concierge::Credentials.for('rentals_united') }

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
        expect(response.body['currency']).to eq("")
        expect(response.body['total']).to eq(284.5)
        expect(response.body['net_rate']).to eq(284.5)
        expect(response.body['host_fee']).to eq(0.0)
        expect(response.body['host_fee_percentage']).to be_nil
      end
    end
  end
end

