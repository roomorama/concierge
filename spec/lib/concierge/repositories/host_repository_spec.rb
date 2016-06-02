require "spec_helper"

RSpec.describe HostRepository do
  include Support::Factories

  describe ".count" do
    it "is zero when there are no records in the database" do
      expect(described_class.count).to eq 0
    end

    it "increases when new records are added" do
      create_host
      expect(described_class.count).to eq 1
    end
  end

  describe ".pending_synchronisation" do
    let!(:pending_host)           { create_host(next_run_at: Time.now - 10) }
    let!(:new_host)               { create_host(next_run_at: nil) }
    let!(:just_synchronised_host) { create_host(next_run_at: Time.now + 60 * 60) }

    it "filters hosts where the next synchronisation time is nil or is in the past" do
      expect(described_class.pending_synchronisation.to_a).to eq [pending_host, new_host]
    end
  end
end
