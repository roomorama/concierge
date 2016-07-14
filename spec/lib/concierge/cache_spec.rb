require "spec_helper"

RSpec.describe Concierge::Cache do
  let(:key) { "test_key" }
  let(:json_serializer) { Concierge::Cache::Serializers::JSON.new }

  describe "#fetch" do
    it "saves the result of an operation to the storage" do
      expect {
        subject.fetch(key) { Result.new("result") }
      }.to change { Concierge::Cache::EntryRepository.count }.by(1)

      entry = Concierge::Cache::EntryRepository.most_recent
      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq "test_key"
      expect(entry.value).to eq "result"
      expect(entry.updated_at).to be_a Time
    end

    it "announces cache misses" do
      miss = Struct.new(:key).new

      Concierge::Announcer.on(Concierge::Cache::CACHE_MISS) do |key|
        miss.key = key
      end

      subject.fetch(key) { Result.new("result") }
      expect(miss.key).to eq "test_key"
    end

    it "namespaces the given key according to the namespace given on initialization" do
      subject = described_class.new(namespace: "supplier.quote")

      expect {
        subject.fetch(key) { Result.new("result") }
      }.to change { Concierge::Cache::EntryRepository.count }.by(1)

      entry = Concierge::Cache::EntryRepository.most_recent
      expect(entry).to be_a Concierge::Cache::Entry
      expect(entry.key).to eq "supplier.quote.test_key"
      expect(entry.value).to eq "result"
      expect(entry.updated_at).to be_a Time
    end

    it "does not perform the calculation in case key is cached" do
      old_entry = create_entry(key, "value")
      result = nil

      expect {
        result = subject.fetch(key) { Result.new("result") }
      }.not_to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_a Result
      expect(result).to be_success

      entry = result.value
      expect(entry).to eq "value"
    end

    it "announces cache hits" do
      hit = Struct.new(:key, :value, :type).new
      Concierge::Announcer.on(Concierge::Cache::CACHE_HIT) do |key, value, type|
        hit.key   = key
        hit.value = value
        hit.type  = type
      end

      create_entry(key, "value")
      subject.fetch(key) { Result.new("result") }

      expect(hit.key).to eq "test_key"
      expect(hit.value).to eq "value"
      expect(hit.type).to eq "text"
    end

    it "does not cache anything if the result indicates failure" do
      result = nil

      expect {
        result = subject.fetch(key) { Result.error(:error) }
      }.not_to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_a Result
      expect(result).not_to be_success

      expect(result.error.code).to eq :error
    end

    it "raises an error if the value returned by a +fetch+ is not a +Result+" do
      expect {
        result = subject.fetch(key) { "unwrapped result" }
      }.to raise_error Concierge::Cache::ResultObjectExpectedError
    end

    it "performs the computation again if the entry is not fresh enough" do
      old_entry = create_entry(key, "value")
      result = nil

      expect {
        result = subject.fetch(key, freshness: 0) { Result.new("result") }
      }.not_to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_a Result
      expect(result).to be_success

      value = result.value
      expect(value).to eq "result"
    end

    it "supports JSON serialization for cached attributes" do
      payload = { key: "value", name: "Supplier" }
      result  = nil

      expect {
        result = subject.fetch(key, serializer: json_serializer) { Result.new(payload) }
      }.to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_success
      expect(result.value).to eq({ "key" => "value", "name" => "Supplier" })

      # test de-serialization works
      expect {
        result = subject.fetch(key, serializer: json_serializer)
      }.not_to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_success
      expect(result.value).to eq({ "key" => "value", "name" => "Supplier" })
    end
  end

  describe "#invalidate" do
    it "has no effect on nonexistent keys" do
      expect {
        subject.invalidate(key)
      }.not_to raise_error
    end

    it "removes the cache entry from the storage" do
      create_entry(key, "value")

      expect {
        subject.invalidate(key)
      }.to change { Concierge::Cache::EntryRepository.count }.by(-1)

      expect(Concierge::Cache::EntryRepository.by_key(key)).to be_nil
    end

    it "executes the computation again" do
      invoked = false
      subject.fetch(key) do
        invoked = true
        Result.new("value")
      end

      expect(invoked).to eq true

      subject.invalidate(key)
      invoked = false

      # cache is invalidated, block should be executed again
      subject.fetch(key) do
        invoked = true
        Result.new("another_value")
      end

      expect(invoked).to eq true

      # simulate a future read, block should be ignored
      read = subject.fetch(key) { Result.error(:error) }

      expect(read.value).to eq "another_value"
    end
  end

  def create_entry(key, value)
    storage = Concierge::Cache::Storage.new

    storage.write(key, value)
    storage.read(key)
  end
end
