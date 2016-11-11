require "spec_helper"

RSpec.describe Concierge::Flows::WorkerJobEnqueue do
  include Support::Factories

  let(:host) { create_host(username: "host1", identifier: "host1") }
  let(:worker) do
    create_background_worker(
      host_id: host.id,
      type: "availabilities",
      next_run_at: nil
    )
  end

  subject { described_class.new(worker) }

  describe "#perform" do
    it "adds worker job to queue and updates worker status" do
      expect_any_instance_of(Workers::Queue).to receive(:add)

      subject.perform

      expect(worker.status).to eq("queued")
    end
  end
end
