require "spec_helper"

RSpec.describe ExternalErrorRepository do
  let(:external_error_attributes) {
    {
      operation:   "quote",
      supplier:    "SupplierA",
      code:        "http_error",
      message:     "Network Failure",
      happened_at: Time.now
    }
  }

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_error
      expect(described_class.count).to eq 1
    end
  end

  describe ".most_recent" do
    it "is nil when the table is empty" do
      expect(described_class.most_recent).to be_nil
    end

    it "returns the most recent external error" do
      create_error(supplier: "Old Supplier")
      create_error(supplier: "New Supplier")

      error = described_class.most_recent
      expect(error).to be_a ExternalError
      expect(error.supplier).to eq "New Supplier"
    end
  end

  private

  def create_error(overrides = {})
    attributes = external_error_attributes.merge(overrides)
    error = ExternalError.new(attributes)

    described_class.create(error)
  end
end
