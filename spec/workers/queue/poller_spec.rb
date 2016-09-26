require "spec_helper"

RSpec.describe Workers::Queue::Poller do
  describe "#poll" do
    class TestPoller
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def poll(*)
        yield(message)
      end

      def delete_message(*)
      end
    end

    let(:message) { "message" }
    let(:poller)  { TestPoller.new(message) }

    subject { described_class.new("queue-url", poller) }

    before do
      allow(subject).to receive(:poller) { poller }
    end

    it "deletes the message immediately after the worker receives it" do
      expect(poller).to receive(:delete_message).with(message)

      subject.poll do
        42
      end
    end

    it "deletes the message if the message processing indicates success" do
      expect(poller).to receive(:delete_message).with(message)

      subject.poll do
        42
      end
    end
  end
end
