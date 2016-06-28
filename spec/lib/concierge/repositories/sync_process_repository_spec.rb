require "spec_helper"

RSpec.describe SyncProcessRepository do
  include Support::Factories

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
end

