require "spec_helper"

RSpec.describe Workers::Processor::BackgroundWorker do
  include Support::Factories

  let(:supplier) { create_supplier(name: "SupplierTest") }
  let(:host)     { create_host(username: "host-test", supplier_id: supplier.id) }
  let(:data)     { Concierge::SafeAccessHash.new(background_worker_id: worker.id) }

  subject { described_class.new(data) }

  describe "#run" do
    shared_examples "returning a Result and saving next run arguments" do
      it "raises an error if the implementation does not return a Result" do
        listening_to("#{worker.type}.#{supplier.name}", block: ->(*) { 42 }) do
          expect {
            subject.run
          }.to raise_error Workers::Processor::BackgroundWorker::NotAResultError
        end
      end

      it "raises an error if the result returned cannot be mapped to a hash" do
        listening_to("#{worker.type}.#{supplier.name}", block: ->(*) { Result.new(42) }) do
          expect {
            subject.run
          }.to raise_error Workers::Processor::BackgroundWorker::NotMappableError
        end
      end

      it "does not save the arguments if there is an issue with the implementation" do
        listening_to("#{worker.type}.#{supplier.name}", block: ->(*) { Result.new(diff_id: "diff124") }) do
          subject.run
        end

        # simulate a bug in the integration
        listening_to("#{worker.type}.#{supplier.name}", block: ->(*) { nil.invalid_method }) do
          expect {
            subject.run
          }.to raise_error NoMethodError
        end

        # reload worker
        reloaded = BackgroundWorkerRepository.find(worker.id)
        expect(reloaded.next_run_args).to eq({ "diff_id" => "diff124" })
      end

      it "saves the arguments and supply them for the next run" do
        listening_to("#{worker.type}.#{supplier.name}", block: ->(*) { Result.new(diff_id: "42") }) do
          subject.run
        end

        listening_to("#{worker.type}.#{supplier.name}", block: ->(_, args) {
          expect(args.to_h).to eq({ "diff_id" => "42" })
          Result.new(diff_id: "24")
        }) do
          subject.run
        end
      end
    end

    context "background workers associated with hosts" do
      let(:worker) { create_background_worker(host_id: host.id, type: "metadata") }

      it_behaves_like "returning a Result and saving next run arguments"

      it "returns early if the worker is currently busy" do
        worker.status = "running"
        BackgroundWorkerRepository.update(worker)

        invoked = 0

        listening_to("metadata.SupplierTest", block: ->(*) {
          invoked += 1
          Result.new({})
        }) do
          result = subject.run
          expect(result).to be_a Result
          expect(result).to be_success
          expect(invoked).to eq 0
        end
      end

      it "triggers the associated supplier synchronisation mechanism on background worker operations" do
        invoked = 0

        listening_to("metadata.SupplierTest", block: ->(*) {
          expect(host.username).to eq "host-test"
          expect(SupplierRepository.find(host.supplier_id).name).to eq "SupplierTest"
          invoked += 1

          expect(BackgroundWorkerRepository.find(worker.id).status).to eq "running"
          Result.new({})
        }) do
          result = subject.run
          expect(result).to be_a Result
          expect(result).to be_success
          expect(invoked).to eq 1

          reloaded_worker = BackgroundWorkerRepository.find(worker.id)
          expect(reloaded_worker.next_run_at - Time.now).to be_within(1).of(worker.interval)
          expect(reloaded_worker.status).to eq "idle"
        end
      end

      it "times out and fails if the operation takes too long" do
        # simulates a timeout of 0.5s and a synchronisation process that takes
        # one second, thus timing out.
        allow(subject).to receive(:processing_timeout) { 0.5 }
        listening_to("metadata.SupplierTest", block: ->(*) { sleep 1 }) do
          result = subject.run
          expect(result).to be_a Result
          expect(result).not_to be_success
          expect(result.error.code).to eq :timeout
        end
      end
    end

    context "background workers associated with suppliers" do
      # worker for aggregated supplier types
      let(:worker) { create_background_worker(host_id: nil, supplier_id: supplier.id, type: "availabilities") }

      it_behaves_like "returning a Result and saving next run arguments"

      it "triggers the associated supplier synchronisation mechanism for the supplier worker" do
        invoked = 0

        listening_to("availabilities.SupplierTest", block: ->(supplier, *) {
          expect(supplier).to be_a Supplier
          expect(supplier.name).to eq "SupplierTest"
          invoked += 1

          expect(BackgroundWorkerRepository.find(worker.id).status).to eq "running"
          Result.new({})
        }) do
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

    it "informs an error when the enqueued ID does not exist on the database" do
      worker  = create_background_worker
      data    = Concierge::SafeAccessHash.new(background_worker_id: worker.id + 1)
      subject = described_class.new(data)

      error = nil
      expect(Rollbar).to receive(:warning) { |err| error = err }

      result = subject.run
      expect(result).to be_a Result
      expect(result).to be_success
      expect(result.value).to eq :invalid_worker_id

      expect(error).to be_a Workers::Processor::BackgroundWorker::UnknownWorkerError
    end

    it "finishes gracefully if the supplier implementation deletes the worker itself" do
      worker  = create_background_worker(type: "metadata", supplier_id: create_supplier(name: "Acme").id)
      data    = Concierge::SafeAccessHash.new(background_worker_id: worker.id)
      subject = described_class.new(data)

      # simulate a supplier implementation that deletes the worker itself
      expect {
        listening_to("metadata.Acme", block: ->(*) {
          BackgroundWorkerRepository.delete(worker)
          Result.new({})
        }) do
          subject.run
        end
      }.not_to raise_error
    end

    def listening_to(event, block:)
      Concierge::Announcer.on(event, &block)
      yield
    ensure
      Concierge::Announcer._announcer.listeners.delete(event)
    end
  end
end
