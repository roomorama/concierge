require "spec_helper"
require_relative "shared/pagination"

RSpec.describe ExternalErrorRepository do
  include Support::Factories

  it_behaves_like "paginating records" do
    let(:factory) { -> { create_external_error } }
  end

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

  describe ".reverse_occurrence" do
    it "returns an empty collection when there are no errors" do
      expect(described_class.reverse_occurrence.to_a).to eq []
    end

    it "returns a sorted collection keeping the most recent error first" do
      recent_error = create_external_error(happened_at: Time.now)
      old_error    = create_external_error(happened_at: Time.now - 4 * 24 * 60 * 60) # 4 days ago

      expect(described_class.reverse_occurrence.to_a).to eq [recent_error, old_error]
    end
  end

  describe ".from_supplier_named" do
    before do
      2.times { create_external_error(supplier: "A") }
      3.times { create_external_error(supplier: "B") }
    end

    it "returns error from a particular error only" do
      expect(described_class.from_supplier_named("A").count).to eq 2
      expect(described_class.from_supplier_named("B").count).to eq 3
    end
  end

  describe ".with_code" do
    it "returns an empty collection if no records match the given code" do
      expect(described_class.with_code("soap_error").to_a).to eq []
    end

    it "returns only errors with the code provided" do
      soap_error   = create_external_error(code: "soap_error")
      http_timeout = create_external_error(code: "http_timeout")

      expect(described_class.with_code("soap_error").to_a).to eq [soap_error]
    end
  end
end
