require "spec_helper"

RSpec.describe Workers::Processor do
  include Support::Factories

  let(:payload) { { operation: "sync", data: { host_id: 2 } } }
  let(:json)    { payload.to_json }

  subject { described_class.new(json) }

  describe "#process!" do
    it "returns an invalid result if the given JSON element is malformed" do
      subject = described_class.new("invalid-json")
      result = subject.process!

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "complains about unknown operations" do
      payload[:operation] = "invalid"

      expect {
        subject.process!
      }.to raise_error Workers::Processor::UnknownOperationError
    end

    it "triggers the associated supplier synchronisation mechanism on sync operations" do
      invoked = false

      Concierge::Announcer.on("sync.AcmeTest") do |host|
        expect(host.username).to eq "acme-host"
        expect(SupplierRepository.find(host.supplier_id).name).to eq "AcmeTest"
        invoked = true
      end

      supplier = create_supplier(name: "AcmeTest")
      host     = create_host(username: "acme-host", supplier_id: supplier.id)
      payload[:data][:host_id] = host.id

      result = subject.process!
      expect(result).to be_a Result
      expect(result).to be_success
      expect(invoked).to eq true
    end

    it "times out and fails if the operation takes too long" do
      supplier = create_supplier(name: "AcmeTest")
      host     = create_host(username: "acme-host", supplier_id: supplier.id)
      payload[:data][:host_id] = host.id

      # simulates a timeout of 0.5s and a synchronisation process that takes
      # one minute, thus timing out.
      allow(subject).to receive(:processing_timeout) { 0.5 }
      Concierge::Announcer.on("sync.AcmeTest") { sleep 1 }

      result = subject.process!
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :timeout
    end
  end
end
