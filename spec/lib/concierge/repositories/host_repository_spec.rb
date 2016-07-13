require "spec_helper"

RSpec.describe HostRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_host
      expect(described_class.count).to eq 1
    end
  end

  describe ".from_supplier" do
    let(:supplier) { create_supplier }

    it "returns an empty collection if there are no hosts for a given supplier" do
      expect(described_class.from_supplier(supplier).to_a).to eq []
    end

    it "returns only hosts that belong to the given supplier" do
      host_from_supplier       = create_host(supplier_id: supplier.id)
      host_from_other_supplier = create_host

      expect(described_class.from_supplier(supplier).to_a).to eq [host_from_supplier]
    end
  end

  describe ".identified_by" do
    it "returns an empty collection when no hosts match the given identifier" do
      expect(described_class.identified_by("identifier").to_a).to eq []
    end

    it "returns only hosts that match the given identifier" do
      host = create_host(identifier: "host1")
      expect(described_class.identified_by("host1").to_a).to eq [host]
    end
  end
end
