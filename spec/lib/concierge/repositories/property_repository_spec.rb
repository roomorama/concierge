require "spec_helper"

RSpec.describe PropertyRepository do
  let(:property_attributes) {
    {
      identifier: "PROP1",
      host_id:    1,
      data:       { title: "Studio Apartment in Madrid" },
    }
  }

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_property
      expect(described_class.count).to eq 1
    end
  end

  describe ".identified_by" do
    it "returns the property identified by the given argument" do
      create_property

      error = described_class.identified_by("PROP1")
      expect(error).to be_a Property
      expect(error.identifier).to eq "PROP1"
    end

    it "is nil in case there is no entry that matches the given identifier" do
      create_property

      expect(described_class.identified_by("invalid")).to be_nil
    end
  end

  private

  def create_property(overrides = {})
    attributes = property_attributes.merge(overrides)
    property   = Property.new(attributes)

    described_class.create(property)
  end
end
