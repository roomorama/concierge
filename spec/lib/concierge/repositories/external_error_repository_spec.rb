require "spec_helper"

RSpec.describe ExternalErrorRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_external_error
      expect(described_class.count).to eq 1
    end
  end

  describe ".update" do
    it "allows an error to be updated and saved back to the database with proper JSON coercion" do
      error = create_external_error(context: { events: [] })
      error.context[:events] << "new-event"

      expect {
        ExternalErrorRepository.update(error)
      }.not_to raise_error
    end
  end

  describe ".most_recent" do
    it "is nil when the table is empty" do
      expect(described_class.most_recent).to be_nil
    end

    it "returns the most recent external error" do
      create_external_error(supplier: "Old Supplier", happened_at: Time.now)
      create_external_error(supplier: "New Supplier", happened_at: Time.now + 10)

      error = described_class.most_recent
      expect(error).to be_a ExternalError
      expect(error.supplier).to eq "New Supplier"
    end
  end

  describe ".paginate" do
    before do
      create_external_error(happened_at: Time.now - 24 * 60 * 60)
      create_external_error(supplier: "SupplierB")
    end

    it "uses the defaults in case the parameters given are nil" do
      collection = described_class.paginate.to_a

      expect(collection.size).to eq 2
      expect(collection.first.supplier).to eq "SupplierB"
      expect(collection.last.supplier).to eq "SupplierA"
    end

    it "uses the defaults in case the parameters given are invalid" do
      collection = described_class.paginate(page: -1, per: -10).to_a

      expect(collection.size).to eq 2
      expect(collection.first.supplier).to eq "SupplierB"
      expect(collection.last.supplier).to eq "SupplierA"
    end

    it "uses the parameters given" do
      collection = described_class.paginate(per: 1).to_a
      expect(collection.size).to eq 1
      expect(collection.first.supplier).to eq "SupplierB"

      collection = described_class.paginate(page: 2).to_a
      expect(collection.size).to eq 0
    end
  end
end
