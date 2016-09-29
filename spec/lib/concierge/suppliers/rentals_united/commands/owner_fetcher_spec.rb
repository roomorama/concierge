require "spec_helper"

RSpec.describe RentalsUnited::Commands::OwnerFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:owner_id) { '123' }
  let(:subject) { described_class.new(credentials, owner_id) }
  let(:url) { credentials.url }

  it "fetches owner" do
    stub_data = read_fixture("rentals_united/owner/owner.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_owner
    expect(result).to be_success

    owner = result.value
    expect(owner).to be_kind_of(RentalsUnited::Entities::Owner)
    expect(owner.id).to eq("419680")
    expect(owner.first_name).to eq("Foo")
    expect(owner.last_name).to eq("Bar")
    expect(owner.email).to eq("foobar@gmail.com")
    expect(owner.phone).to eq("519461272")
  end

  it "returns error when there is no requested owner" do
    stub_data = read_fixture("rentals_united/owner/not_found.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.fetch_owner
    expect(result).not_to be_success
    expect(result.error.code).to eq(:unrecognised_response)
  end

  context "when response from the api has error status" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/owner/error_status.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.fetch_owner

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

      result = subject.fetch_owner

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

      result = subject.fetch_owner

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
