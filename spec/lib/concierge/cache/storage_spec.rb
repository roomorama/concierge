require "spec_helper"

RSpec.describe Concierge::Cache::Storage do
  let(:key) { "supplier.operation.cache_key" }
  let(:entry) { Concierge::Cache::Entry.new(key: key, value: "resulting value") }

  shared_examples "recovering from database failures" do |operation, args|
    before do
      [:by_key, :create, :update, :delete].each do |action|
        allow(Concierge::Cache::EntryRepository).to receive(action) { raise Hanami::Model::UniqueConstraintViolationError }
      end
    end

    it "does not raise a hard failure in case there is an issue at the database level" do
      expect {
        subject.public_send(operation, *args)
      }.not_to raise_error
    end
  end

  describe "#read" do
    it_behaves_like "recovering from database failures", :read, ["key"]

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
    it_behaves_like "recovering from database failures", :write, ["key", "value"]

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
    it_behaves_like "recovering from database failures", :delete, ["key"]

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
