require "spec_helper"

RSpec.describe BackgroundWorkerRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when the underlying database has no records" do
      expect(described_class.count).to eq 0
    end

    it "returns the number of records in the database" do
      2.times { create_background_worker }
      expect(described_class.count).to eq 2
    end
  end

  describe ".for_host" do
    it "returns an empty collection when there are no workers" do
      expect(described_class.for_host(create_host).to_a).to eq []
    end

    it "returns workers associated with the given host only" do
      host              = create_host
      host_worker       = create_background_worker(host_id: host.id)
      other_host_worker = create_background_worker

      expect(described_class.for_host(host).to_a).to eq [host_worker]
    end
  end

  describe ".for_supplier" do
    it "returns an empty collection when there are no workers" do
      expect(described_class.for_supplier(create_supplier).to_a).to eq []
    end

    it "returns workers associated with the given supplier only" do
      supplier              = create_supplier(name: "Supplier 1")
      supplier_worker       = create_background_worker(supplier_id: supplier.id)
      other_supplier_worker = create_background_worker(supplier_id: create_supplier(name: "Supplier 2").id)
      host_worker           = create_background_worker(host_id: create_host.id)

      expect(described_class.for_supplier(supplier).to_a).to eq [supplier_worker]
    end
  end

  describe ".pending" do
    let(:one_hour) { 60 * 60 }
    let(:now) { Time.now }

    it "returns an empty collection if all workers are to be run in the future" do
      worker = create_background_worker(next_run_at: now + one_hour)
      expect(described_class.pending.to_a).to eq []
    end

    it "returns only workers with null timestamps or timestamps in the past which are not already running" do
      new_worker     = create_background_worker(next_run_at: nil)
      future_worker  = create_background_worker(next_run_at: now + one_hour)
      pending_worker = create_background_worker(next_run_at: now - one_hour)

      new_running_worker     = create_background_worker(next_run_at: nil, status: "running")
      pending_running_worker = create_background_worker(next_run_at: now - one_hour, status: "running")

      expect(described_class.pending.to_a).to eq [pending_worker, new_worker]
    end
  end
end
