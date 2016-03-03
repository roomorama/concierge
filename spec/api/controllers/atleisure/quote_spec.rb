require "spec_helper"
require_relative "../shared/quote_validations"

RSpec.describe API::Controllers::AtLeisure::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new }

  describe "#call" do
    let(:endpoint) { AtLeisure::Price::ENDPOINT }
    let(:params) {
      { property_id: "AT-123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }

    before do
      allow_any_instance_of(API::Support::JSONRPC).to receive(:request_id) { 888888888888 }
    end

    it "returns an error message in case there is a failure with the request" do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
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
