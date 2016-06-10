require "spec_helper"

RSpec.describe Concierge::Cache::EntryRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_cache_entry
      expect(described_class.count).to eq 1
    end
  end

  describe ".most_recent" do
    it "is nil when the table is empty" do
      expect(described_class.most_recent).to be_nil
    end

    it "returns the most recent external error" do
      create_cache_entry(key: "old.key")
      create_cache_entry(key: "new.key")

      entry = described_class.most_recent
      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq "new.key"
    end
  end

  describe ".by_key" do
    it "is nil when the table is empty" do
      expect(described_class.by_key("some key")).to be_nil
    end

    it "is nil when the key given is not associated with any record" do
      create_cache_entry
      expect(described_class.by_key("invalid.key")).to be_nil
    end

    it "returns the cache entry associated with a given key" do
      create_cache_entry(key: "the.key")
      entry = described_class.by_key("the.key")

      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq "the.key"
    end
  end
end
