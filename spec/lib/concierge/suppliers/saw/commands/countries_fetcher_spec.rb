require "spec_helper"

RSpec.describe SAW::Commands::CountriesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }

  it "returns results with an array of countries" do
    mock_request(:country, :multiple)

    results = subject.call
    countries = results.value

    expect(results.success?).to be true
    expect(countries.size).to eq(4)
    expect(countries.map {|c| { id: c.id, name: c.name }}).to eq([
      { id: "1", name: "United States" },
      { id: "2", name: "Canada" },
      { id: "3", name: "Brazil" },
      { id: "4", name: "France" },
    ])
  end

  it "returns results when there is only one country" do
    mock_request(:country, :one)

    results = subject.call
    countries = results.value

    expect(results.success?).to be true
    expect(countries.size).to eq(1)
    expect(countries.map {|c| { id: c.id, name: c.name }}).to eq([
      { id: "1", name: "United States" }
    ])
  end

  it "returns an empty array when there is no countries" do
    mock_request(:country, :empty)

    results = subject.call
    countries = results.value

    expect(results.success?).to be true
    expect(countries.size).to eq(0)
  end

  it "returns failure result when SAW API returns an error" do
    mock_request(:country, :error)

    results = subject.call
    countries = results.value

    expect(results.success?).to be false
    expect(results.error.code).to eq("9999")
    expect(results.error.data).to eq("Custom Error")
    expect(last_context_event[:message]).to eq(
      "Response indicating the error `9999`, and description `Custom Error`"
    )
    expect(last_context_event[:backtrace]).to be_kind_of(Array)
    expect(last_context_event[:backtrace].any?).to be true
    expect(countries).to be_nil
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:country)

      result = subject.call

      expect(result.success?).to be false
      expect(result.error.code).to eq(:unrecognised_response)
      expect(result.error.data).to eq("Internal Server Error\n")
      expect(last_context_event[:message]).to eq(
        "Error response could not be recognised (no `code` or `description` fields)."
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:country)

      result = subject.call

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end
  end
end
