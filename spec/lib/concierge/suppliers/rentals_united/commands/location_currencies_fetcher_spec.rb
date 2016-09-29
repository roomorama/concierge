require "spec_helper"

RSpec.describe RentalsUnited::Commands::LocationCurrenciesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:subject) { described_class.new(credentials) }
  let(:url) { credentials.url }

  it "fetches currencies for locations" do
    stub_data = read_fixture("rentals_united/location_currencies/currencies.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_location_currencies
    expect(result).to be_success
    expect(result.value.size).to eq(3)
    expect(result.value["7892"]).to eq("AUD")
    expect(result.value["4530"]).to eq("CAD")
    expect(result.value["4977"]).to eq("CAD")
  end

  it "returns nil locations which has no currency" do
    stub_data = read_fixture("rentals_united/location_currencies/currencies.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_location_currencies
    expect(result).to be_success
    expect(result.value.size).to eq(3)
    expect(result.value["1111"]).to be_nil
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/location_currencies/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_location_currencies

      expect(result).not_to be_success
      expect(result.error.code).to eq("9999")

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Response indicating the Status with ID `9999`, and description ``"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_location_currencies

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(
        "Error response could not be recognised (no `Status` tag in the response)"
      )
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.fetch_location_currencies

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
