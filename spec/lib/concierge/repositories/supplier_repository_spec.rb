require "spec_helper"

RSpec.describe SupplierRepository do
  let(:supplier_attributes) {
    { name: "Supplier A" }
  }

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_supplier
      expect(described_class.count).to eq 1
    end
  end

  describe ".named" do
    it "returns the supplier associated with the given name" do
      create_supplier(name: "Supplier X")
      supplier = described_class.named("Supplier X")

      expect(supplier).to be_a Supplier
      expect(supplier.name).to eq "Supplier X"
    end

    it "is nil if the name cannot be found" do
      create_supplier
      expect(described_class.named("Supplier X")).to be_nil
    end
  end

  private

  def create_supplier(overrides = {})
    attributes = supplier_attributes.merge(overrides)
    supplier = Supplier.new(attributes)

    described_class.create(supplier)
  end
end
