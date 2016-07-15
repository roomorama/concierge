require "spec_helper"

RSpec.describe Concierge::Flows::HostCreation do
  include Support::Factories

  let(:supplier) { create_supplier(name: "Supplier X") }

  let(:parameters) {
    {
      supplier:     supplier,
      identifier:   "host1",
      username:     "roomorama-user",
      access_token: "a1b2c3",
      fee_percentage:   7
    }
  }

  def config_suppliers(file)
    parameters[:config_path] = Hanami.root.join("spec", "fixtures", "suppliers_configuration", file).to_s
  end

  before do
    config_suppliers "suppliers.yml"
  end

  subject { described_class.new(parameters) }

  describe "#perform" do
    it "returns an unsuccessful if any required parameter is missing" do
      [nil, ""].each do |invalid_value|
        [:supplier, :identifier, :username, :access_token, :fee_percentage].each do |attribute|
          parameters[attribute] = invalid_value

          result = subject.perform
          expect(result).to be_a Result
          expect(result).not_to be_success
          expect(result.error.code).to eq :invalid_parameters
        end
      end
    end

    it "returns an unsuccessful result without a workers definition" do
      config_suppliers "no_supplier_x.yml"

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :no_workers_definition
    end

    it "returns an unsuccessful result if parameters for the workers are missing" do
      config_suppliers "no_metadata_interval.yml"

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "returns an unsuccessful result if the worker type is unknown" do
      config_suppliers "invalid_worker_type.yml"

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "returns an unsuccessful result if the interval specified is not recognised" do
      config_suppliers "invalid_interval.yml"

      result = subject.perform
      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_parameters
    end

    it "creates the host and associated workers" do
      expect {
        expect {
          expect(subject.perform).to be_success
        }.to change { HostRepository.count }.by(1)
      }.to change { BackgroundWorkerRepository.count }.by(2)

      host     = HostRepository.last
      workers  = BackgroundWorkerRepository.for_host(host).to_a

      expect(host.identifier).to eq "host1"
      expect(host.username).to eq "roomorama-user"
      expect(host.access_token).to eq "a1b2c3"
      expect(host.fee_percentage).to eq 7

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

      host     = HostRepository.last
      workers  = BackgroundWorkerRepository.for_host(host).to_a
      metadata_worker = workers.find { |w| w.type == "metadata" }

      expect(metadata_worker.interval).to eq 24 * 60 * 60

      # updates metadata worker interval to every 2 days
      config_suppliers "2d_interval.yml"

      expect {
        described_class.new(parameters).perform
      }.not_to change { HostRepository.count }

      metadata_worker = BackgroundWorkerRepository.find(metadata_worker.id)
      expect(metadata_worker.interval).to eq 2 * 24 * 60 * 60 # 2 days
    end

    context "interval parsing" do
      it "understands seconds notation" do
        config_suppliers "seconds_interval.yml"
        subject.perform

        host   = HostRepository.last
        worker = BackgroundWorkerRepository.
          for_host(host).
          find { |w| w.type == "availabilities" }

        expect(worker.interval).to eq 10
      end

      it "understands minutes notation" do
        config_suppliers "minutes_interval.yml"
        subject.perform

        host   = HostRepository.last
        worker = BackgroundWorkerRepository.
          for_host(host).
          find { |w| w.type == "availabilities" }

        expect(worker.interval).to eq 10 * 60
      end
    end
  end
end
