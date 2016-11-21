require "spec_helper"

RSpec.describe Concierge::SupplierConfig do

  def config_path(file)
    Hanami.root.join("spec", "fixtures", "suppliers_configuration", file).to_s
  end

  before do
    described_class.reload!(config_path("suppliers.yml"))
  end

  describe "#suppliers" do
    it "returns list of supplier names" do
      expect(described_class.suppliers).to eq ["Supplier X", "Supplier FOO"]
    end

    it "returns empty list when config is empty" do
      described_class.reload!(config_path("empty.yml"))

      expect(described_class.suppliers).to eq []
    end
  end

  describe "for" do
    it "returns config hash for the supplier" do
      config = described_class.for("Supplier X")
      expect(config).to be_a(Hash)
      expect(config["path"]).to eq("supplier_x")
    end

    it "returns nil for unknown supplier" do
      config = described_class.for("Supplier Unknown")
      expect(config).to be_nil
    end
  end

  describe "validate_suppliers!" do
    described_class::REQUIRED_FIELDS.each do |field|
      it "raises exception if supplier without #{field} field" do
        described_class.reload!(config_path("no_#{field}_suppliers.yml"))
        expect { described_class.validate_suppliers! }.
          to raise_error(%<Missing field "#{field}" for supplier "Supplier FOO">)
      end
    end

    it "raises exception if worker has invalid type" do
      described_class.reload!(config_path("invalid_worker_type.yml"))

      expect { described_class.validate_suppliers! }.
        to raise_error(%<Invalid worker type "invalid" for supplier "Supplier X">)
    end

    it "raises exception if worker has empty config" do
      described_class.reload!(config_path("empty_worker_config.yml"))

      expect { described_class.validate_suppliers! }.
        to raise_error(%<Error "metadata" worker definition for supplier "Supplier FOO". Empty config.>)
    end

    it "raises exception if worker does not have absence or interval config" do
      described_class.reload!(config_path("no_absence_no_interval.yml"))

      expect { described_class.validate_suppliers! }.
        to raise_error(%<Error "metadata" worker definition for supplier "Supplier FOO". It should contain "absence" or "every" field>)
    end

    context "conflicting keys" do
      %w(absence_interval absence_aggregated).each do |scenario|
        fields = scenario.sub("_", " and ") # "absence_interval" => "absence and interval"

        it "returns an unsuccessful result if the definition has both #{fields}" do
          described_class.reload!(config_path("conflicting_#{scenario}.yml"))

          expect { described_class.validate_suppliers! }.
            to raise_error(%<Error "availabilities" worker definition for supplier "Supplier X". "absence" worker should not contain any other configs>)
        end
      end
    end
  end
end
