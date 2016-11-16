require "spec_helper"

RSpec.describe Concierge::SupplierRoutes do
  let(:suppliers_list) {
    [
      "AtLeisure", "WayToStay", "Ciirus", "SAW",
      "Kigo", "KigoLegacy", "Poplidays", "RentalsUnited",
      "Avantio", "THH", "JTB"
    ]
  }

  describe "#declared_suppliers" do
    it "should be match known list" do
      expect(described_class.declared_suppliers).to match_array suppliers_list
    end
  end

  describe "#sub_path" do
    it "should match" do
      expect(described_class.sub_path("Kigo")).to eq "kigo"
      expect(described_class.sub_path("KigoLegacy")).to eq "kigo/legacy"
      expect(described_class.sub_path("SAW")).to eq "saw"
      expect(described_class.sub_path("WayToStay")).to eq "waytostay"

      expect { described_class.sub_path("NewSupplier") }.to raise_error NoMethodError
    end
  end

  describe "#controller_name" do
    it "should match" do
      expect(described_class.controller_name("Kigo")).to eq "kigo"
      expect(described_class.controller_name("KigoLegacy")).to eq "kigo/legacy"
      expect(described_class.controller_name("SAW")).to eq "s_a_w"
      expect(described_class.controller_name("WayToStay")).to eq "waytostay"

      expect { described_class.controller_name("NewSupplier") }.to raise_error NoMethodError
    end
  end
end

