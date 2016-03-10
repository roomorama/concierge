require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::AtLeisure::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:params) {
    { property_id: "AT-123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
  }
  let(:endpoint) { AtLeisure::Price::ENDPOINT }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { "AtLeisure" }

    def provoke_failure!
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      Struct.new(:code, :message).new("connection_timeout", "timeout")
    end
  end

  describe "#call" do
    before do
      allow_any_instance_of(API::Support::JSONRPC).to receive(:request_id) { 888888888888 }
    end

    ["atleisure/no_availability.json", "atleisure/no_price.json", "atleisure/on_request.json"].each do |fixture|
      it "returns a proper error message if return looks like fixture #{fixture}" do
        stub_call(:post, endpoint) { [200, {}, jsonrpc_fixture(fixture)] }
        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 503
        expect(response.body["status"]).to eq "error"
        expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
      end
    end

    it "returns unavailable quotation when the supplier responds so" do
        stub_call(:post, endpoint) { [200, {}, jsonrpc_fixture("atleisure/unavailable.json")] }
        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body["status"]).to eq "ok"
        expect(response.body["available"]).to eq false
        expect(response.body["property_id"]).to eq "AT-123"
        expect(response.body["check_in"]).to eq "2016-03-22"
        expect(response.body["check_out"]).to eq "2016-03-25"
        expect(response.body["guests"]).to eq 2
        expect(response.body).not_to have_key("currency")
        expect(response.body).not_to have_key("total")
    end

    it "returns available quotations with price when the call is successful" do
        stub_call(:post, endpoint) { [200, {}, jsonrpc_fixture("atleisure/available.json")] }
        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 200
        expect(response.body["status"]).to eq "ok"
        expect(response.body["available"]).to eq true
        expect(response.body["property_id"]).to eq "AT-123"
        expect(response.body["check_in"]).to eq "2016-03-22"
        expect(response.body["check_out"]).to eq "2016-03-25"
        expect(response.body["guests"]).to eq 2
        expect(response.body["currency"]).to eq "EUR"
        expect(response.body["total"]).to eq 150
    end

  end

  def parse_response(rack_response)
    Shared::QuoteResponse.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end

  def jsonrpc_fixture(name)
    {
      id: 888888888888,
      result: JSON.parse(read_fixture(name))
    }.to_json
  end

end
