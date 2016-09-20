require "spec_helper"

RSpec.describe Concierge::Queue::Poller do
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

    it "ensures that the result from the message processing block is a valid Result instance" do
      expect {
        subject.poll do
          42
        end
      }.to raise_error Concierge::Queue::Poller::InvalidQueueProcessingResultError
    end

    it "does not delete the message if the message processing indicates failure" do
      expect(poller).not_to receive(:delete_message).with(message)

      subject.poll do
        Result.error(:something_went_wrong)
      end
    end

    it "deletes the message if the message processing indicates success" do
      expect(poller).to receive(:delete_message).with(message)

      subject.poll do
        Result.new(42)
      end
    end
  end
end
