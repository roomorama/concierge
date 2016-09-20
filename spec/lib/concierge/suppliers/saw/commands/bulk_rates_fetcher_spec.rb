require "spec_helper"

RSpec.describe SAW::Commands::BulkRatesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::SAW::MockRequest
  include Support::SAW::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:subject) { described_class.new(credentials) }
  let(:property_ids) { ["1", "2", "3"] }

  it "returns rates for given property ids" do
    mock_request(:propertyrates, :success_multiple_properties)

    result = subject.call(property_ids)
    expect(result).to be_success

    rates = result.value
    expect(rates).to be_kind_of(Array)
    expect(rates.size).to eq(2)
    expect(rates).to all(be_kind_of(SAW::Entities::UnitsPricing))
  end

  it "returns rates for single property id" do
    mock_request(:propertyrates, :success_multiple_units)

    result = subject.call(property_ids)
    expect(result).to be_success

    rates = result.value
    expect(rates).to be_kind_of(Array)
    expect(rates.size).to eq(1)
    expect(rates).to all(be_kind_of(SAW::Entities::UnitsPricing))
  end

  it "returns a result with an empty array if all rates are unavailable" do
    mock_request(:propertyrates, :rates_not_available)

    result = subject.call(property_ids)
    expect(result).to be_success

    rates = result.value

    expect(rates).to be_kind_of(Array)
    expect(rates.size).to eq(0)
  end

  it "returns result with error after error" do
    mock_request(:propertyrates, :error)

    result = subject.call(property_ids)
    expect(result).not_to be_success

    expect(result.error.code).to eq("0000")
    expect(last_context_event[:message]).to eq(
      "Response indicating the error `0000`, and description `Strange Error`"
    )
    expect(last_context_event[:backtrace]).to be_kind_of(Array)
    expect(last_context_event[:backtrace].any?).to be true
  end

  context "when response from the SAW api is not well-formed xml" do
    it "returns a result with an appropriate error" do
      mock_bad_xml_request(:propertyrates)

      result = subject.call(property_ids)

      expect(result).not_to be_success
      expect(result.error.code).to eq(:unrecognised_response)
      expect(last_context_event[:message]).to eq(
        "Error response could not be recognised (no `code` or `description` fields)."
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:propertyrates)

      result = subject.call(property_ids)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
