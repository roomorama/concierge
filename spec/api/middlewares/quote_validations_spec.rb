require "spec_helper"

RSpec.describe API::Middlewares::QuoteValidations do
  include Support::Factories

  let(:quote_request) {
    {
      property_id: "023",
      check_in: "2016-10-01",
      check_out: "2016-10-05",
      guests: 2
    }
  }

  let(:request_body) { StringIO.new(quote_request.to_json) }
  let(:app) { Rack::MockRequest.new(subject) }
  let(:response) { "OK" }
  let(:upstream) { lambda { |env| [200, {}, response] } }
  let(:headers) {
    {
      input: request_body,
      "CONTENT_TYPE" => "application/json"
    }
  }

  subject { described_class.new(upstream) }

  describe "Not a quote request" do
    it "does not touch the request" do
      expect(post("/supplierx/cancel", headers)).to eq [200, { "Content-Length" => response.size.to_s }, response]
    end
  end

  describe "Property and host exists" do
    let!(:host) { create_host(fee_percentage: 7) }
    let!(:property) { create_property(identifier:"023", host_id: host.id) }

    it "forwards to upstream" do
      expect(post("/supplierx/quote", headers)).to eq [200, { "Content-Length" => response.size.to_s }, response]
    end
  end

  describe "Unknown property and host" do
    let(:property_not_found) {
      [404, { "Content-Length" => "31" }, "Property not found on Concierge"]
    }

    before do
      PropertyRepository.clear
      HostRepository.clear
    end

    it "returns 404" do
      expect(post("/supplierx/quote", headers)).to eq property_not_found
    end
  end

  def post(path, params = {})
    to_rack(app.post(path, params))
  end

  def to_rack(response)
    [
      response.status,
      response.header,
      response.body
    ]
  end
end
