require "spec_helper"
require_relative "shared/pagination"

RSpec.describe SyncProcessRepository do
  include Support::Factories

  it_behaves_like "paginating records" do
    let(:factory) { -> { create_sync_process } }
  end

  describe ".successful" do
    let!(:successful_sync) { create_sync_process(successful: true) }
    let!(:unsuccessful_sync) { create_sync_process(successful: false) }

    subject { described_class.successful.to_a }

    it { expect(subject).to include successful_sync }
    it { expect(subject).not_to include unsuccessful_sync }
  end

  describe ".most_recent" do
    it "is empty in case there are no sync processes" do
      expect(described_class.most_recent.to_a).to eq []
    end

    it "orders the collection bringing the most recent process first" do
      recent = create_sync_process(started_at: Time.now)
      old = create_sync_process(started_at: Time.now - 4 * 24 * 60 * 60) # 4 days ago

      expect(described_class.most_recent.to_a).to eq [recent, old]
    end
  end

  describe ".for_host" do
    let(:host) { create_host }
    let!(:sync_with_host) { create_sync_process(host_id: host.id) }
    let!(:sync_without_host) { create_sync_process }

    subject { described_class.for_host(host).to_a }

    it { expect(subject).to include sync_with_host }
    it { expect(subject).not_to include sync_without_host }
  end

  describe ".of_type" do
    it "is empty if the there are no records" do
      expect(described_class.of_type("metadata").to_a).to eq []
    end

    it "is empty if type is empty" do
      expect(described_class.of_type("").to_a).to eq []
    end

    it "is empty if type is nil" do
      expect(described_class.of_type(nil).to_a).to eq []
    end

    it "returns synchronisation process of the given type only" do
      metadata_process       = create_sync_process(type: "metadata")
      availabilities_process = create_sync_process(type: "availabilities")

      expect(described_class.of_type("metadata").to_a).to eq [metadata_process]
    end
  end
end
