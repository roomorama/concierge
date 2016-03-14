require "spec_helper"
require_relative "../shared/quote_validations"
require_relative "../shared/external_error_reporting"

RSpec.describe API::Controllers::Poplidays::Quote do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:params) {
    { property_id: "48327", check_in: "2016-12-17", check_out: "2016-12-26", guests: 2 }
  }
  let(:property_details_endpoint) { "https://api.poplidays.com/v2/lodgings/48327" }
  let(:calendar_endpoint) { "https://api.poplidays.com/v2/lodgings/48327/availabilities" }

  it_behaves_like "performing parameter validations", controller_generator: -> { described_class.new } do
    let(:valid_params) { params }
  end

  it_behaves_like "external error reporting" do
    let(:supplier_name) { "Poplidays" }

    def provoke_failure!
      stub_call(:get, calendar_endpoint) { raise Faraday::TimeoutError }
      Struct.new(:code, :message).new("connection_timeout", "timeout - https://api.poplidays.com/v2/lodgings/48327/availabilities")
    end
  end

  describe "#call" do
    [
      ["poplidays/availabilities_calendar_no_availabilities.json", nil],
      ["poplidays/availabilities_calendar.json", "poplidays/property_details_missing_mandatory_services.json"],
      ["poplidays/unexpected_xml_response.xml", nil]
    ].each do |calendar_fixture, property_details_fixture|
      it "returns a proper error message if the responses look like fixtures #{calendar_fixture} and #{property_details_fixture}" do
        stub_call(:get, calendar_endpoint) { [200, {}, read_fixture(calendar_fixture)] }
        # if a fixture for the property details is not given, we do not stub
        # that call, meaning we expect it never to be triggered.
        if property_details_fixture
          stub_call(:get, property_details_endpoint) { [200, {}, read_fixture(property_details_fixture)] }
        end

        response = parse_response(described_class.new.call(params))

        expect(response.status).to eq 503
        expect(response.body["status"]).to eq "error"
        expect(response.body["errors"]["quote"]).to eq "Could not quote price with remote supplier"
      end
    end

    it "returns unavailable quotation when the supplier responds so" do
      params[:check_in] = "2016-03-22"
      params[:check_out] = "2016-03-25"
      stub_call(:get, calendar_endpoint) { [200, {}, read_fixture("poplidays/availabilities_calendar.json")] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq false
      expect(response.body["property_id"]).to eq "48327"
      expect(response.body["check_in"]).to eq "2016-03-22"
      expect(response.body["check_out"]).to eq "2016-03-25"
      expect(response.body["guests"]).to eq 2
      expect(response.body).not_to have_key("currency")
      expect(response.body).not_to have_key("total")
    end

    it "returns available quotations with price when the call is successful" do
      stub_call(:get, calendar_endpoint) { [200, {}, read_fixture("poplidays/availabilities_calendar.json")] }
      stub_call(:get, property_details_endpoint) { [200, {}, read_fixture("poplidays/property_details.json")] }

      response = parse_response(described_class.new.call(params))

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["available"]).to eq true
      expect(response.body["property_id"]).to eq "48327"
      expect(response.body["check_in"]).to eq "2016-12-17"
      expect(response.body["check_out"]).to eq "2016-12-26"
      expect(response.body["guests"]).to eq 2
      expect(response.body["currency"]).to eq "EUR"
      expect(response.body["total"]).to eq 3638 + 25 # rental + mandatory services
    end

  end

  def parse_response(rack_response)
    Shared::QuoteResponse.new(
      rack_response[0],
      rack_response[1],
      JSON.parse(rack_response[2].first)
    )
  end

end
