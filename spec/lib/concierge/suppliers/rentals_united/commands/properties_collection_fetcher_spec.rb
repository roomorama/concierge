require "spec_helper"

RSpec.describe RentalsUnited::Commands::PropertiesCollectionFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:owner_id) { "1234" }
  let(:subject) { described_class.new(credentials, owner_id) }
  let(:url) { credentials.url }

  it "returns an empty collection when there is no properties in location" do
    stub_data = read_fixture("rentals_united/properties_collection/empty_list.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_properties_collection_for_owner
    expect(result).to be_success

    collection = result.value
    expect(collection).to be_kind_of(
      RentalsUnited::Entities::PropertiesCollection
    )
    expect(collection.size).to eq(0)
    expect(collection.property_ids).to eq([])
    expect(collection.location_ids).to eq([])
  end

  it "returns collection when there is only one property" do
    stub_data = read_fixture("rentals_united/properties_collection/one_property.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_properties_collection_for_owner
    expect(result).to be_success

    collection = result.value
    expect(collection).to be_kind_of(
      RentalsUnited::Entities::PropertiesCollection
    )
    expect(collection.size).to eq(1)
    expect(collection.property_ids).to eq(["519688"])
    expect(collection.location_ids).to eq(["24958"])
  end

  it "returns collection with multiple objects" do
    stub_data = read_fixture("rentals_united/properties_collection/multiple_properties.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_properties_collection_for_owner
    expect(result).to be_success

    collection = result.value
    expect(collection).to be_kind_of(
      RentalsUnited::Entities::PropertiesCollection
    )
    expect(collection.size).to eq(2)
    expect(collection.property_ids).to eq(["519688", "519689"])
    expect(collection.location_ids).to eq(["24958"])
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/properties_collection/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_properties_collection_for_owner

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
    let(:expected_error_message) { "Error response could not be recognised (no `Status` tag in the response)" }

    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_properties_collection_for_owner

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)
      expect(result.error.data).to eq(expected_error_message)

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq(expected_error_message)
      expect(event[:backtrace]).to be_kind_of(Array)
      expect(event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:post, url) { raise Faraday::TimeoutError }

      result = subject.fetch_properties_collection_for_owner

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
