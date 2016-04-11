require "spec_helper"

RSpec.describe Concierge::Cache::Storage do
  let(:key) { "supplier.operation.cache_key" }
  let(:entry) { Concierge::Cache::Entry.new(key: key, value: "resulting value") }

  describe "#read" do
    it "returns nil in case there is no cache entry with the given key" do
      expect(subject.read(key)).to eq nil
    end

    it "returns an Entry object associated with the given cache key" do
      Concierge::Cache::EntryRepository.create(entry)
      cached = subject.read(key)

      expect(cached).to be_a Concierge::Cache::Entry
      expect(cached.value).to eq "resulting value"
    end
  end

  describe "#write" do
    it "creates a new cache entry if none exist for the given key" do
      expect {
        subject.write(key, "resulting value")
      }.to change { Concierge::Cache::EntryRepository.count }.by(1)

      entry = Concierge::Cache::EntryRepository.last
      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq key
      expect(entry.value).to eq "resulting value"
    end

    it "udpates the existing cached record in case the entry is already cached" do
      Concierge::Cache::EntryRepository.create(entry)

      expect {
        subject.write(key, "resulting value modified")
      }.not_to change { Concierge::Cache::EntryRepository.count }

      entry = Concierge::Cache::EntryRepository.last
      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq key
      expect(entry.value).to eq "resulting value modified"
    end
  end

  describe "#delete" do
    it "does nothing if there is no entry associated with the given key" do
      expect {
        subject.delete(key)
      }.not_to change { Concierge::Cache::EntryRepository.count }
    end

    it "removes the entry associated with the given key if it exists" do
      Concierge::Cache::EntryRepository.create(entry)

      expect {
        subject.delete(key)
      }.to change { Concierge::Cache::EntryRepository.count }.by(-1)

      expect(subject.read(key)).to eq nil
    end
  end

end
