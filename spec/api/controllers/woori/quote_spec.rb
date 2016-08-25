require "spec_helper"
require_relative "../shared/multi_unit_quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Woori::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  it_behaves_like "performing multi unit parameter validations",
    controller_generator: -> { described_class.new }

  it_behaves_like "external error reporting" do
    let(:params) do
      {
        property_id: "321",
        unit_id: "123",
        check_in: "2016-03-22",
        check_out: "2016-03-25",
        guests: 2
      }
    end
    let(:supplier_name) { "Woori" }
    let(:url) { "http://my.test/available" }

    def provoke_failure!
      stub_call(:get, url) { raise Faraday::TimeoutError }
      Struct.new(:code).new("connection_timeout")
    end
  end

  describe "#call" do
    let(:url) { "http://my.test/available" }

    context "when params are valid" do
      let(:params) do
        {
          property_id: "321",
          unit_id: "123",
          check_in: "2016-03-22",
          check_out: "2016-03-25",
          guests: 2
        }
      end

      it "respond with successfull response" do
        stub_data = read_fixture("woori/quotations/success.json")
        stub_call(:get, url) { [200, {}, stub_data] }

        response = parse_response(subject.call(params))
        expect(response.status).to eq 200
        expect(response.body['status']).to eq("ok")
        expect(response.body['available']).to be true
        expect(response.body['property_id']).to eq("321")
        expect(response.body['unit_id']).to eq("123")
        expect(response.body['check_in']).to eq("2016-03-22")
        expect(response.body['check_out']).to eq("2016-03-25")
        expect(response.body['guests']).to eq(2)
        expect(response.body['currency']).to eq("KRW")
        expect(response.body['total']).to eq(280000.0)
        expect(response.body['net_rate']).to eq(280000.0)
        expect(response.body['host_fee']).to eq(0.0)
        expect(response.body['host_fee_percentage']).to be_nil
      end
    end

    context "when stay length is > 30 days" do
      let(:params) do
        {
          property_id: "J123",
          unit_id: "123J",
          check_in: "2016-02-22",
          check_out: "2016-03-25",
          guests: 2
        }
      end

      it "respond with unavailable quotation" do
        response = parse_response(subject.call(params))
        expect(response.status).to eq 200
        expect(response.body['status']).to eq("ok")
        expect(response.body['available']).to be false
        expect(response.body['property_id']).to eq("J123")
        expect(response.body['unit_id']).to eq("123J")
        expect(response.body['check_in']).to eq("2016-02-22")
        expect(response.body['check_out']).to eq("2016-03-25")
        expect(response.body['guests']).to eq(2)
      end
    end
  end
end
