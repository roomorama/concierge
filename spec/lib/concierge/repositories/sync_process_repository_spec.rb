require "spec_helper"
require_relative "shared/pagination"

RSpec.describe SyncProcessRepository do
  include Support::Factories

  it_behaves_like "paginating records" do
    let(:factory) { -> { create_sync_process } }
  end

  describe ".recent_successful_sync_for_host" do
    let(:now) { Time.new(2016, 06, 06) }
    let(:one_hour_ago)       { now -  1 * 60 * 60 }
    let(:twenty_minutes_ago) { now - 20 * 60 }
    let(:ten_minutes_ago)    { now - 10 * 60 }
    let(:five_minutes_ago)   { now -  5 * 60 }
    let(:host) { create_host }

    before(:each)do
      create_sync_process(successful: false, started_at: one_hour_ago, host_id: host.id)
      create_sync_process(successful: true,  started_at: twenty_minutes_ago, host_id: host.id)
      create_sync_process(successful: true,  started_at: ten_minutes_ago, host_id: host.id)
      create_sync_process(successful: false, started_at: five_minutes_ago, host_id: host.id)
    end

    subject { described_class.recent_successful_sync_for_host(host) }
    it { expect(subject.first.started_at).to eq ten_minutes_ago }
    it { expect(subject.all.last.started_at).to eq twenty_minutes_ago }

    context "when there is no successful sync" do
      subject { described_class.recent_successful_sync_for_host(create_host) }
      it { expect(subject.first).to be_nil }
    end

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
