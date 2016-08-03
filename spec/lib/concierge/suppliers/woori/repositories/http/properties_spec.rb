require "spec_helper"

RSpec.describe Woori::Repositories::HTTP::Properties do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:url) { "http://my.test/properties" }
  let(:updated_at) { "1970-01-01" }
  let(:limit) { 50 }
  let(:offset) { 0 }

  it "returns results with an array of properties" do
    stub_data = read_fixture("woori/properties/success.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.load_updates(updated_at, limit, offset)
    expect(result.success?).to be true

    properties = result.value

    expect(properties.size).to eq(5)
    expect(properties).to all(be_kind_of(Roomorama::Property))
  end
  
  it "returns results when there is only one property" do
    stub_data = read_fixture("woori/properties/one.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.load_updates(updated_at, limit, offset)
    expect(result.success?).to be true
    
    properties = result.value

    expect(properties.size).to eq(1)
    expect(properties).to all(be_kind_of(Roomorama::Property))
  end

  it "returns an empty array when there is no properties" do
    stub_data = read_fixture("woori/properties/empty.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.load_updates(updated_at, limit, offset)
    expect(result.success?).to be true
    
    properties = result.value
    expect(properties.size).to eq(0)
  end

  it "returns failure result when Woori API returns an error" do
    stub_data = read_fixture("woori/error_500.json")
    stub_call(:get, url) { [500, {}, stub_data] }

    result = subject.load_updates(updated_at, limit, offset)
    
    expect(result.success?).to be false
    expect(result.error.code).to eq(:http_status_500)
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/bad_response.json")
      stub_call(:get, url) { [200, {}, stub_data] }

      result = subject.load_updates(updated_at, limit, offset)

      expect(result.success?).to be false
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:get, url) { raise Faraday::TimeoutError }

      result = subject.load_updates(updated_at, limit, offset)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
