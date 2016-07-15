require "spec_helper"

RSpec.describe Woori::Commands::PropertiesFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::MockRequest
  include Support::Woori::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }

  it "returns results with an array of properties" do
    mock_request(:properties, :success)

    results = subject.call
    expect(results.success?).to be true

    properties = results.value

    expect(properties.size).to eq(5)
    expect(properties).to all(be_kind_of(Roomorama::Property))
  end
  
  it "returns results when there is only one property" do
    mock_request(:properties, :one)

    results = subject.call
    expect(results.success?).to be true
    
    properties = results.value

    expect(properties.size).to eq(1)
    expect(properties).to all(be_kind_of(Roomorama::Property))
  end

  it "returns an empty array when there is no properties" do
    mock_request(:properties, :empty)

    results = subject.call
    expect(results.success?).to be true
    
    properties = results.value
    expect(properties.size).to eq(0)
  end

  it "returns failure result when Woori API returns an error" do
    mock_request(:properties, :error_500)

    results = subject.call
    properties = results.value

    expect(results.success?).to be false
    # expect(results.error.code).to eq("9999")
    # expect(last_context_event[:message]).to eq(
    #   "Response indicating the error `9999`, and description `Custom Error`"
    # )
    # expect(last_context_event[:backtrace]).to be_kind_of(Array)
    # expect(last_context_event[:backtrace].any?).to be true
    # expect(countries).to be_nil
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      mock_bad_json_request(:properties)

      result = subject.call

      expect(result.success?).to be false
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      mock_timeout_error(:properties)

      result = subject.call

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
