require "spec_helper"

RSpec.describe Concierge::Flows::SupplierCreation do
  let(:parameters) {
    {
      name: "Supplier X",
      workers: {
        metadata: {
          every: "1d"
        },
        availabilities: {
          every: "2h"
        }
      }
    }
  }

  subject { described_class.new(parameters) }

  describe "#perform" do
    it "returns an unsuccessful result without a valid name" do
      [nil, ""].each do |invalid_name|
        parameters[:name] = invalid_name

        result = subject.perform
        expect(result).to be_a Result
        expect(result).not_to be_success
        expect(result.error.code).to eq :invalid_parameters
      end
    end

    it "returns an unsuccessful result without a workers definition" do
      parameters.delete(:workers)

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "returns an unsuccessful result if parameters for the workers are missing" do
      parameters[:workers][:metadata].delete(:every)

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "returns an unsuccessful result if the worker type is unknown" do
      parameters[:workers][:invalid] = parameters[:workers].delete(:metadata)

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "returns an unsuccessful result if the interval specified is not recognised" do
      parameters[:workers][:metadata][:every] = "invalid"

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "creates supplier and associated workers" do
      expect {
        expect {
          expect(subject.perform).to be_success
        }.to change { SupplierRepository.count }.by(1)
      }.to change { BackgroundWorkerRepository.count }.by(2)

      supplier = SupplierRepository.last
      workers  = BackgroundWorkerRepository.for_supplier(supplier).to_a

      expect(supplier.name).to eq "Supplier X"
      expect(workers.size).to eq 2

      worker = workers.first
      expect(worker.type).to eq "metadata"
      expect(worker.next_run_at).to be_nil
      expect(worker.interval).to eq 24 * 60 * 60 # one day
      expect(worker.status).to eq "idle"

      worker = workers.last
      expect(worker.type).to eq "availabilities"
      expect(worker.next_run_at).to be_nil
      expect(worker.interval).to eq 2 * 60 * 60 # two hours
      expect(worker.status).to eq "idle"
    end

    it "updates changed data on consecutive runs" do
      subject.perform

      supplier = SupplierRepository.named("Supplier X")
      workers  = BackgroundWorkerRepository.for_supplier(supplier).to_a
      metadata_worker = workers.find { |w| w.type == "metadata" }

      expect(metadata_worker.interval).to eq 24 * 60 * 60

      # updates metadata worker interval to every 2 days
      parameters[:workers][:metadata][:every] = "2d"

      expect {
        subject.perform
      }.not_to change { SupplierRepository.count }

      metadata_worker = BackgroundWorkerRepository.find(metadata_worker.id)
      expect(metadata_worker.interval).to eq 2 * 24 * 60 * 60 # 2 days
    end

    context "interval parsing" do
      it "understands seconds notation" do
        parameters[:workers][:availabilities][:every] = "10s"
        subject.perform

        supplier = SupplierRepository.named("Supplier X")
        worker   = BackgroundWorkerRepository.
          for_supplier(supplier).
          find { |w| w.type == "availabilities" }

        expect(worker.interval).to eq 10
      end

      it "understands minutes notation" do
        parameters[:workers][:availabilities][:every] = "10m"
        subject.perform

        supplier = SupplierRepository.named("Supplier X")
        worker   = BackgroundWorkerRepository.
          for_supplier(supplier).
          find { |w| w.type == "availabilities" }

        expect(worker.interval).to eq 10 * 60
      end
    end
  end
end
