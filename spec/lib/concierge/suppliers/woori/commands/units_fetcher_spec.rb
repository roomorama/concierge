require "spec_helper"

RSpec.describe Woori::Commands::UnitsFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:property_id) { "w_w0104006" }
  let(:url) { "http://my.test/properties/#{property_id}/roomtypes" }

  it "returns results with an array of units" do
    stub_data = read_fixture("woori/units/success.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(property_id)
    expect(result.success?).to be true

    properties = result.value

    expect(properties.size).to eq(9)
    expect(properties).to all(be_kind_of(Roomorama::Unit))
  end
  
  it "returns results when there is only one unit" do
    stub_data = read_fixture("woori/units/one.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(property_id)
    expect(result.success?).to be true

    properties = result.value

    expect(properties.size).to eq(1)
    expect(properties).to all(be_kind_of(Roomorama::Unit))
  end

  it "returns an empty array when there is no units" do
    stub_data = read_fixture("woori/units/empty.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(property_id)
    expect(result.success?).to be true

    properties = result.value
    expect(properties.size).to eq(0)
  end

  it "returns failure result when Woori API returns an error" do
    stub_data = read_fixture("woori/error_500.json")
    stub_call(:get, url) { [500, {}, stub_data] }

    result = subject.call(property_id)

    expect(result.success?).to be false
    expect(result.error.code).to eq(:http_status_500)
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/bad_response.json")
      stub_call(:get, url) { [200, {}, stub_data] }

      result = subject.call(property_id)

      expect(result.success?).to be false
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:get, url) { raise Faraday::TimeoutError }

      result = subject.call(property_id)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
