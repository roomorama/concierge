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

  describe ".for_supplier" do
    let(:supplier) { create_supplier }

    it "returns an empty list if there are no workers for a given supplier" do
      expect(described_class.for_supplier(supplier).to_a).to eq []
    end

    it "returns a collection of background workers for a supplier" do
      %w(metadata availabilities).each do |type|
        create_background_worker(supplier_id: supplier.id, type: type)
      end

      expect(described_class.for_supplier(supplier).to_a.size).to eq 2
    end
  end
end
