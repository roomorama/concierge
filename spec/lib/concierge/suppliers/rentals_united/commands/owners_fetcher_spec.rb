require "spec_helper"

RSpec.describe RentalsUnited::Commands::OwnersFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { credentials.url }

  it "fetches owners" do
    stub_data = read_fixture("rentals_united/owners/owners.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_owners
    expect(result).to be_success

    owners = result.value
    expect(owners).to all(be_kind_of(RentalsUnited::Entities::Owner))
    expect(owners.size).to eq(2)

    expected_owner_ids = %w(427698 419680)
    expected_owner_ids.each do |owner_id|
      expect(owners.map(&:id).include?(owner_id)).to be true
    end
  end

  it "returns [] when there is no owners" do
    stub_data = read_fixture("rentals_united/owners/empty.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_owners
    expect(result).to be_success

    owners = result.value
    expect(owners).to eq([])
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/owners/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_owners

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

      result = subject.fetch_owners

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

      result = subject.fetch_owners

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
