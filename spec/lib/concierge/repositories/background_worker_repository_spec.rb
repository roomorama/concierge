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
end
