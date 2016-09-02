require "spec_helper"

RSpec.describe RentalsUnited::Commands::CitiesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { credentials.url }
  let(:expected_locations) {{'1505' => 1, '2503' => 1, '1144' => 2}}

  it "returns an empty array when there is no active properties" do
    stub_data = read_fixture("rentals_united/cities/empty_list.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_cities
    expect(result).to be_success
    expect(result.value).to eq([])
  end

  it "returns city object when there is one city" do
    stub_data = read_fixture("rentals_united/cities/one_city.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_cities
    expect(result).to be_success
    expect(result.value).to be_kind_of(Array)
    expect(result.value.size).to eq(1)
    expect(result.value).to all(be_kind_of(RentalsUnited::Entities::City))

    city = result.value.first
    expect(city.location_id).to eq("1505")
    expect(city.properties_count).to eq(1)
  end

  it "returns multiple city objects" do
    stub_data = read_fixture("rentals_united/cities/multiple_cities.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_cities
    expect(result).to be_success

    cities = result.value
    expect(cities).to be_kind_of(Array)
    expect(cities.size).to eq(3)
    expect(cities).to all(be_kind_of(RentalsUnited::Entities::City))

    expected_locations.each do |location_id, properties_count|
      city = cities.find { |c| c.location_id == location_id }
      expect(city.properties_count).to eq(properties_count)
    end
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/cities/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_cities

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

      result = subject.fetch_cities

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

      result = subject.fetch_cities

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
