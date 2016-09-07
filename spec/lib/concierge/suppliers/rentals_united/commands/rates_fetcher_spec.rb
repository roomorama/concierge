require "spec_helper"

RSpec.describe RentalsUnited::Commands::RatesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:property_id) { "1234" }
  let(:subject) { described_class.new(credentials, property_id) }
  let(:url) { credentials.url }

  it "returns an error if property does not exist" do
    stub_data = read_fixture("rentals_united/rates/not_found.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_rates
    expect(result).not_to be_success
    expect(result.error.code).to eq("56")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `56`, and description `Property does not exist.`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  it "returns an empty array if property have no rates seasons" do
    stub_data = read_fixture("rentals_united/rates/no_seasons.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_rates
    expect(result).to be_success
    expect(result.value).to eq([])
  end

  context "when response contains rates data" do
    let(:file_name) { "rentals_united/rates/success.xml" }

    before do
      stub_data = read_fixture(file_name)
      stub_call(:post, url) { [200, {}, stub_data] }
    end

    it "returns rates" do
      result = subject.fetch_rates
      expect(result).to be_success
      expect(result.value.size).to eq(2)
      expect(result.value).to all(be_kind_of(RentalsUnited::Entities::Rate))
    end
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_rates

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

      result = subject.fetch_rates

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
