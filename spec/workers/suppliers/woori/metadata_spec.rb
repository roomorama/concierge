require "spec_helper"

RSpec.describe Workers::Suppliers::Woori::Metadata do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures
  include Support::Woori::LastContextEvent

  let(:host) { create_host }
  let(:url) { "http://my.test/properties" }

  describe "#perform operation" do
    let(:worker) do
      described_class.new(host)
    end
    
    it "fails when fetching properties returns an error" do
      stub_data = read_fixture("woori/error_500.json")
      stub_call(:get, url) { [500, {}, stub_data] }

      result = worker.perform

      expect(result).to be_nil
      expect(last_context_event[:label]).to eq(
        "Synchronisation Failure"
      )
      expect(last_context_event[:message]).to eq(
        "Failed to perform the `#fetch_properties` operation"
      )
      expect(last_context_event[:backtrace]).to be_kind_of(Array)
      expect(last_context_event[:backtrace].any?).to be true
    end
  end
end
