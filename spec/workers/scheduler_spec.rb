require "spec_helper"

RSpec.describe Workers::Scheduler do
  include Support::Factories

  let!(:new_host)     { create_host(username: "new_host", identifier: "host1") }
  let!(:pending_host) { create_host(username: "pending_host", identifier: "host2") }
  let!(:future_host)  { create_host(username: "future_host", identifier: "host3") }

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
    xit "does nothing in case there is no host to be synchronised" do
      HostRepository.all.each do |host|
        HostRepository.update(host)
      end

      expect(subject).not_to receive(:enqueue)
      subject.trigger_pending!

      expect(logger.messages).to eq []
    end

    xit "triggers only new hosts and hosts that are pending" do
      expect(subject).to receive(:enqueue).twice
      subject.trigger_pending!

      expect(logger.messages).to eq [
        "action=sync host.username=pending_host host.identifier=host2",
        "action=sync host.username=new_host host.identifier=host1",
      ]

      new_reloaded = HostRepository.find(new_host.id)
      pending_reloaded = HostRepository.find(pending_host.id)
    end
  end
end
