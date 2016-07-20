require "spec_helper"

RSpec.describe Workers::Processor do
  include Support::Factories

  let(:payload) { { operation: "background_worker", data: { background_worker_id: 2 } } }
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

    it "returns early if the worker is currently busy" do
      supplier = create_supplier(name: "AcmeTest")
      host     = create_host(username: "acme-host", supplier_id: supplier.id)
      worker   = create_background_worker(host_id: host.id, type: "metadata", status: "running")
      payload[:data][:background_worker_id] = worker.id

      invoked = false

      Concierge::Announcer.on("metadata.AcmeTest") do
        invoked = true
      end

      result = subject.process!
      expect(result).to be_a Result
      expect(result).to be_success
      expect(invoked).to eq false
    end

    it "triggers the associated supplier synchronisation mechanism on background worker operations" do
      invoked = false

      supplier = create_supplier(name: "AcmeTest")
      host     = create_host(username: "acme-host", supplier_id: supplier.id)
      worker   = create_background_worker(host_id: host.id, type: "metadata", interval: 10)
      payload[:data][:background_worker_id] = worker.id

      Concierge::Announcer.on("metadata.AcmeTest") do |host|
        expect(host.username).to eq "acme-host"
        expect(SupplierRepository.find(host.supplier_id).name).to eq "AcmeTest"
        invoked = true

        expect(BackgroundWorkerRepository.find(worker.id).status).to eq "running"
      end

      result = subject.process!
      expect(result).to be_a Result
      expect(result).to be_success
      expect(invoked).to eq true

      reloaded_worker = BackgroundWorkerRepository.find(worker.id)
      expect(reloaded_worker.next_run_at - Time.now).to be_within(1).of(worker.interval)
      expect(reloaded_worker.status).to eq "idle"
    end

    it "times out and fails if the operation takes too long" do
      supplier = create_supplier(name: "AcmeTest")
      host     = create_host(username: "acme-host", supplier_id: supplier.id)
      worker   = create_background_worker(host_id: host.id, type: "availabilities")
      payload[:data][:background_worker_id] = worker.id

      # simulates a timeout of 0.5s and a synchronisation process that takes
      # one minute, thus timing out.
      allow(subject).to receive(:processing_timeout) { 0.5 }
      Concierge::Announcer.on("availabilities.AcmeTest") { sleep 1 }

      result = subject.process!
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :timeout
    end
  end
end
