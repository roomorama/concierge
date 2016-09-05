require "spec_helper"

RSpec.describe Woori::Commands::CalendarFetcher do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:subject) { described_class.new(credentials) }
  let(:property) do
    Property.new(
      id: 1,
      identifier: '123',
      data: Concierge::SafeAccessHash.new(units: units)
    )
  end

  let(:units) do
    [{ identifier: '1'}, { identifier: '2'} ]
  end

  let(:url) { "http://my.test/available" }

  context "when there is no units in property" do
    let(:units) { [] }

    it "returns empty calendar when there is not units in property" do
      result = subject.call(property)
      expect(result.success?).to be true

      calendar = result.value
      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.entries).to eq([])
    end
  end

  it "returns result wrapping a calendar object" do
    stub_data = read_fixture("woori/unit_rates/success.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(property)
    expect(result.success?).to be true

    calendar = result.value
    expect(calendar).to be_kind_of(Roomorama::Calendar)
  end

  it "returns nil when there is no rates information" do
    stub_data = read_fixture("woori/unit_rates/empty.json")
    stub_call(:get, url) { [200, {}, stub_data] }

    result = subject.call(property)
    expect(result.success?).to be true

    calendar = result.value
    expect(calendar).to be_kind_of(Roomorama::Calendar)
    expect(calendar.entries).to eq([])
  end

  it "returns failure result when Woori API returns an error" do
    stub_data = read_fixture("woori/error_500.json")
    stub_call(:get, url) { [500, {}, stub_data] }

    result = subject.call(property)

    expect(result.success?).to be false
    expect(result.error.code).to eq(:http_status_500)
  end

  context "when response from the Woori api is not well-formed json" do
    it "returns a result with an appropriate error" do
      stub_data = read_fixture("woori/bad_response.json")
      stub_call(:get, url) { [200, {}, stub_data] }

      result = subject.call(property)

      expect(result.success?).to be false
      expect(result.error.code).to eq(:invalid_json_representation)
    end
  end

  context "when request fails due to timeout error" do
    it "returns a result with an appropriate error" do
      stub_call(:get, url) { raise Faraday::TimeoutError }

      result = subject.call(property)

      expect(result).not_to be_success
      expect(Concierge.context.events.last.to_h[:message]).to eq("timeout")
      expect(result.error.code).to eq :connection_timeout
    end
  end
end
