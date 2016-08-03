require "spec_helper"

RSpec.describe Woori::Repositories::HTTP::UnitRates do
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::LastContextEvent

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:unit_id) { "w_w0104006_R01" }
  let(:url) { "http://my.test/available" }

  it "returns result wrapping a unit rates object" do
    stub_data = read_fixture("woori/unit_rates/success.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.find_rates(unit_id)
    expect(result.success?).to be true

    unit_rates = result.value
    expect(unit_rates).to be_kind_of(Woori::Entities::UnitRates)
  end
  
  it "returns nil when there is no rates information" do
    stub_data = read_fixture("woori/unit_rates/empty.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.find_rates(unit_id)
    expect(result.success?).to be true

    unit_rates = result.value
    expect(unit_rates).to be_nil
  end

  it "returns failure result when Woori API returns an error" do
    stub_data = read_fixture("woori/error_500.json")
    stub_call(:get, url) { [500, {}, stub_data] }

    result = subject.find_rates(unit_id)

    expect(result.success?).to be false
    expect(result.error.code).to eq(:http_status_500)
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/bad_response.json")
      stub_call(:get, url) { [200, {}, stub_data] }

      result = subject.find_rates(unit_id)

      expect(result.success?).to be false
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:get, url) { raise Faraday::TimeoutError }

      result = subject.find_rates(unit_id)

      expect(result).not_to be_success
      expect(last_context_event[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
