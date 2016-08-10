require "spec_helper"

RSpec.describe Concierge::Flows::RemoteHostCreation do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:supplier) { create_supplier(name: "Supplier X") }

  let(:parameters) {
    {
      host_identifier: "host1",
      config:          {"phone": "+6598765432", "fee_percentage": 7},
      supplier:        supplier,
      access_token:    "a1b2c3",
    }
  }

  subject { described_class.new(parameters) }

  describe "#perform" do
    it "returns an error if host exists" do
      create_host(identifier: parameters[:host_identifier])
      res = subject.perform
      expect(res.error.code).to eq :host_exists
    end

    it "creates host on roomorama and then concierge" do
      # stub roomorama api
      endpoint = "https://api.staging.roomorama.com#{Roomorama::Client::Operations::CreateHost::ENDPOINT}"
      stub_call(:post, endpoint) { [202, {}, read_fixture("roomorama/create-host.json")] }

      # stub concierge creation
      host_creation = double("HostCreation")
      expect(Concierge::Flows::HostCreation).to receive(:new) { |**args|
        expect(args[:access_token]).to eq "new_access_token"
        host_creation
      }
      expect(host_creation).to receive(:perform)
      subject.perform
    end
  end
end
