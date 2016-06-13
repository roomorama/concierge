require "spec_helper"

RSpec.describe Workers::Scheduler do
  include Support::Factories

  let!(:new_host)     { create_host(username: "new_host", identifier: "host1", next_run_at: nil) }
  let!(:pending_host) { create_host(username: "pending_host", identifier: "host2", next_run_at: Time.now - 10) }
  let!(:future_host)  { create_host(username: "future_host", identifier: "host3", next_run_at: Time.now + 60 * 60) }

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
    it "does nothing in case there is no host to be synchronised" do
      HostRepository.all.each do |host|
        host.next_run_at = Time.now + 60*60
        HostRepository.update(host)
      end

      expect(subject).not_to receive(:enqueue)
      subject.trigger_pending!

      expect(logger.messages).to eq []
    end

    it "triggers only new hosts and hosts that are pending" do
      expect(subject).to receive(:enqueue).twice
      subject.trigger_pending!

      expect(logger.messages).to eq [
        "action=sync host.username=pending_host host.identifier=host2",
        "action=sync host.username=new_host host.identifier=host1",
      ]

      new_reloaded = HostRepository.find(new_host.id)
      pending_reloaded = HostRepository.find(pending_host.id)

      expect(new_reloaded.next_run_at > Time.now).to eq true
      expect(pending_reloaded.next_run_at > Time.now).to eq true
    end
  end
end
