require "spec_helper"

RSpec.describe RentalsUnited::Commands::PropertyIdsFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:location_id) { "1234" }
  let(:subject) { described_class.new(credentials, location_id) }
  let(:url) { credentials.url }

  it "returns an empty array when there is no properties in location" do
    stub_data = read_fixture("rentals_united/properties/empty_list.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_property_ids
    expect(result).to be_success
    expect(result.value).to eq([])
  end

  it "returns property idwhen there is only one property" do
    stub_data = read_fixture("rentals_united/properties/one_property.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_property_ids
    expect(result).to be_success
    expect(result.value).to be_kind_of(Array)
    expect(result.value.size).to eq(1)
    expect(result.value).to all(be_kind_of(String))

    property_id = result.value.first
    expect(property_id).to eq("519688")
  end

  it "returns multiple city objects" do
    stub_data = read_fixture("rentals_united/properties/multiple_properties.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_property_ids
    expect(result).to be_success

    properties = result.value
    expect(properties).to be_kind_of(Array)
    expect(properties.size).to eq(2)
    expect(properties).to all(be_kind_of(String))
    expect(properties).to eq(["519688", "519689"])
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/properties/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_property_ids

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

      result = subject.fetch_property_ids

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

      result = subject.fetch_property_ids

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
