require "spec_helper"

RSpec.describe Concierge::Cache do
  let(:key) { "test_key" }

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

    it "does not cache anything if the result indicates failure" do
      result = nil

      expect {
        result = subject.fetch(key) { Result.error(:error, "Something went wrong") }
      }.not_to change { Concierge::Cache::EntryRepository.count }

      expect(result).to be_a Result
      expect(result).not_to be_success

      expect(result.error.code).to eq :error
      expect(result.error.message).to eq "Something went wrong"
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

    private

    def create_entry(key, value)
      storage = Concierge::Cache::Storage.new

      storage.write(key, value)
      storage.read(key)
    end
  end
end
