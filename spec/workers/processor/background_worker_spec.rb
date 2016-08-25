require "spec_helper"

RSpec.describe Workers::Processor::BackgroundWorker do
  include Support::Factories

  let(:supplier) { create_supplier(name: "SupplierTest") }
  let(:host)     { create_host(username: "host-test", supplier_id: supplier.id) }
  let(:data) { Concierge::SafeAccessHash.new(background_worker_id: worker.id) }

  subject { described_class.new(data) }

  describe "#run" do
    context "background workers associated with hosts" do
      let(:worker) { create_background_worker(host_id: host.id, type: "metadata") }

      it "returns early if the worker is currently busy" do
        worker.status = "running"
        BackgroundWorkerRepository.update(worker)

        invoked = 0

        Concierge::Announcer.on("metadata.SupplierTest") do
          invoked += 1
        end

        result = subject.run
        expect(result).to be_a Result
        expect(result).to be_success
        expect(invoked).to eq 0
      end

      it "triggers the associated supplier synchronisation mechanism on background worker operations" do
        # updates supplier name so there is no conflict with event names in the
        # same RSpec run
        supplier.name = "SupplierTest2"
        SupplierRepository.update(supplier)

        invoked = 0

        Concierge::Announcer.on("metadata.SupplierTest2") do |host|
          expect(host.username).to eq "host-test"
          expect(SupplierRepository.find(host.supplier_id).name).to eq "SupplierTest2"
          invoked += 1

          expect(BackgroundWorkerRepository.find(worker.id).status).to eq "running"
        end

        result = subject.run
        expect(result).to be_a Result
        expect(result).to be_success
        expect(invoked).to eq 1

        reloaded_worker = BackgroundWorkerRepository.find(worker.id)
        expect(reloaded_worker.next_run_at - Time.now).to be_within(1).of(worker.interval)
        expect(reloaded_worker.status).to eq "idle"
      end

      it "times out and fails if the operation takes too long" do
        # simulates a timeout of 0.5s and a synchronisation process that takes
        # one second, thus timing out.
        allow(subject).to receive(:processing_timeout) { 0.5 }
        Concierge::Announcer.on("metadata.SupplierTest") { sleep 1 }

        result = subject.run
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :timeout
      end
    end

    context "background workers associated with suppliers" do
      # worker for aggregated supplier types
      let(:worker) { create_background_worker(host_id: nil, supplier_id: supplier.id, type: "availabilities") }

      it "triggers the associated supplier synchronisation mechanism for the supplier worker" do
        invoked = 0

        Concierge::Announcer.on("availabilities.SupplierTest") do |supplier|
          expect(supplier).to be_a Supplier
          expect(supplier.name).to eq "SupplierTest"
          invoked += 1

          expect(BackgroundWorkerRepository.find(worker.id).status).to eq "running"
        end

        result = subject.run
        expect(result).to be_a Result
        expect(result).to be_success
        expect(invoked).to eq 1

        reloaded_worker = BackgroundWorkerRepository.find(worker.id)
        expect(reloaded_worker.next_run_at - Time.now).to be_within(1).of(worker.interval)
        expect(reloaded_worker.status).to eq "idle"
      end
    end
  end
end
