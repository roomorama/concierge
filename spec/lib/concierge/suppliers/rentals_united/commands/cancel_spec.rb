require "spec_helper"

RSpec.describe RentalsUnited::Commands::Cancel do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:reference_number) { "888999777" }
  let(:subject) { described_class.new(credentials, reference_number) }
  let(:url) { credentials.url }

  it "performs successful cancel request" do
    stub_data = read_fixture("rentals_united/cancel/success.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).to be_kind_of(Result)
    expect(result).to be_success

    expect(result.value).to eq(reference_number)
  end

  it "returns error if reservation does not exist" do
    stub_data = read_fixture("rentals_united/cancel/does_not_exist.xml")
    stub_call(:post, url) { [200, {}, stub_data] }

    result = subject.call

    expect(result).to be_kind_of(Result)
    expect(result).not_to be_success
    expect(result.error.code).to eq("28")

    event = Concierge.context.events.last.to_h
    expect(event[:message]).to eq(
      "Response indicating the Status with ID `28`, and description `Reservation does not exist.`"
    )
    expect(event[:backtrace]).to be_kind_of(Array)
    expect(event[:backtrace].any?).to be true
  end

  context "when response from the api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("rentals_united/bad_xml.xml")
      stub_call(:post, url) { [200, {}, stub_data] }

      result = subject.call

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

      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout

      event = Concierge.context.events.last.to_h
      expect(event[:message]).to eq("timeout")
    end
  end
end
