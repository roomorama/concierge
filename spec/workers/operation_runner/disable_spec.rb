require "spec_helper"

RSpec.describe Workers::OperationRunner::Disable do
  include Support::Factories
  include Support::HTTPStubbing

  let(:endpoint) { "https://api.roomorama.com/v1.0/host/disable" }
  let(:host) { create_host }
  let(:identifiers) { ["prop1", "prop2"] }
  let(:operation) { Roomorama::Client::Operations.disable(identifiers) }
  let(:roomorama_client) { Roomorama::Client.new(host.access_token) }

  subject { described_class.new(host, operation, roomorama_client) }

  describe "#perform" do
    it "returns the underlying network problem, if any" do
      stub_call(:delete, endpoint) { raise Faraday::TimeoutError }
      result = subject.perform

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "saves the context information" do
      stub_call(:delete, endpoint) { raise Faraday::TimeoutError }

      expect {
        subject.perform
      }.to change { Concierge.context.events.size }

      event = Concierge.context.events.last
      expect(event).to be_a Concierge::Context::NetworkFailure
    end

    it "returns successfully and removes the corresponding database records" do
      # properties to be deleted
      create_property(identifier: "prop1", host_id: host.id)
      create_property(identifier: "prop2", host_id: host.id)

      # properties from the same host, different identifiers - should not be deleted
      create_property(identifier: "same-host", host_id: host.id)

      # properties from different hosts, but same identifier - should not be deleted
      create_property(identifier: "prop1", host_id: create_host.id)

      stub_call(:delete, endpoint) { [202, {}, [""]] }
      result = subject.perform

      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to eq true

      expect(PropertyRepository.from_host(host).identified_by(["prop1", "prop2"]).to_a).to eq []
      expect(PropertyRepository.identified_by("same-host").to_a.size).to eq 1
      expect(PropertyRepository.identified_by("prop1").to_a.size).to eq 1
    end
  end
end
