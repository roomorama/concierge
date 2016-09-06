require "spec_helper"

RSpec.describe RentalsUnited::Commands::LocationIdsFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { credentials.url }
  let(:expected_locations) { ['1505', '2503', '1144'] }

  it "returns an empty array when there is no active properties" do
    stub_data = read_fixture("rentals_united/location_ids/empty_list.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_location_ids
    expect(result).to be_success
    expect(result.value).to eq([])
  end

  it "returns array with location id when there is one location" do
    stub_data = read_fixture("rentals_united/location_ids/one_location.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_location_ids
    expect(result).to be_success
    expect(result.value).to be_kind_of(Array)
    expect(result.value.size).to eq(1)
    expect(result.value).to all(be_kind_of(String))

    location_id = result.value.first
    expect(location_id).to eq("1505")
  end

  it "returns multiple location ids" do
    stub_data = read_fixture("rentals_united/location_ids/multiple_locations.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_location_ids
    expect(result).to be_success

    location_ids = result.value
    expect(location_ids).to be_kind_of(Array)
    expect(location_ids.size).to eq(3)
    expect(location_ids).to all(be_kind_of(String))
    expect(location_ids.sort).to eq(expected_locations.sort)
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/location_ids/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_location_ids

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

      result = subject.fetch_location_ids

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

      result = subject.fetch_location_ids

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
