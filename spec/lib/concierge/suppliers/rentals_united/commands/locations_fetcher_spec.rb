require "spec_helper"

RSpec.describe RentalsUnited::Commands::LocationsFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:location_ids) { ["1505"] }
  let(:subject) { described_class.new(credentials, location_ids) }
  let(:url) { credentials.url }

  it "fetches and returns one location" do
    stub_data = read_fixture("rentals_united/locations/locations.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_locations
    expect(result).to be_success
    expect(result.value.size).to eq(1)

    location = result.value.first
    expect(location).to be_kind_of(RentalsUnited::Entities::Location)
    expect(location.id).to eq("1505")
    expect(location.city).to eq("Paris")
    expect(location.region).to eq("Ile-de-France")
    expect(location.country).to eq("France")
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/locations/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_locations

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

      result = subject.fetch_locations

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

      result = subject.fetch_locations

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
