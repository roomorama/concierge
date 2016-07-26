require "spec_helper"

RSpec.describe Workers::Scheduler do
  include Support::Factories

  class LoggerStub
    attr_reader :messages

    def initialize
      @messages = []
    end

    def info(message)
      messages << message
    end
  end

  let(:logger) { LoggerStub.new }
  subject { described_class.new(logger: logger) }

  describe "#trigger_pending!" do
    it "does nothing in case there is no background worker to be run" do
      expect(subject).not_to receive(:enqueue)
      subject.trigger_pending!

      expect(logger.messages).to eq []
    end

    it "triggers only new workers and hosts that are pending" do
      host = create_host(username: "host1", identifier: "host1")
      new_worker     = create_background_worker(host_id: host.id,        type: "availabilities", next_run_at: nil)
      pending_worker = create_background_worker(host_id: host.id,        type: "metadata",       next_run_at: Time.now - 60 * 60)
      future_worker  = create_background_worker(host_id: create_host.id, type: "metadata",       next_run_at: Time.now + 60 * 60)

      expect(subject).to receive(:enqueue).twice
      subject.trigger_pending!

      expect(logger.messages).to eq [
        "action=metadata host.username=host1 host.identifier=host1",
        "action=availabilities host.username=host1 host.identifier=host1",
      ]

      new_reloaded = BackgroundWorkerRepository.find(new_worker.id)
      pending_reloaded = BackgroundWorkerRepository.find(pending_worker.id)

      expect(new_reloaded.status).to eq "idle"
      expect(pending_reloaded.status).to eq "idle"
    end
  end
end
