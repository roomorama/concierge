require "spec_helper"

RSpec.describe SyncProcessRepository do
  include Support::Factories

  describe ".last_successful_sync_start_time_for_host" do
    let(:one_hour_ago)       { Time.now -  1 * 60 * 60 }
    let(:twenty_minutes_ago) { Time.now - 20 * 60 }
    let(:ten_minutes_ago)    { Time.now - 10 * 60 }
    let(:five_minutes_ago)   { Time.now -  5 * 60 }
    let(:host) { create_host }
    before do
      create_sync_process(successful: false, started_at: one_hour_ago, host_id: host.id)
      create_sync_process(successful: true,  started_at: twenty_minutes_ago, host_id: host.id)
      create_sync_process(successful: true,  started_at: ten_minutes_ago, host_id: host.id)
      create_sync_process(successful: false, started_at: five_minutes_ago, host_id: host.id)
    end

    subject { described_class.last_successful_sync_for_host host }
    it { expect(subject.started_at).to eq ten_minutes_ago }
  end
end

