require "spec_helper"

RSpec.describe Workers::Queue do
  let(:credentials) { Concierge::Credentials.for("sqs") }
  let(:element) { Workers::Queue::Element.new(operation: "sync", data: { key: "value" }) }
  subject { described_class.new(credentials) }

  describe "#add" do
    it "denies invalid elements" do
      element = Workers::Queue::Element.new(operation: nil, data: {})

      expect {
        subject.add(element)
      }.to raise_error Workers::Queue::Element::InvalidOperationError
    end

    it "enqueues the message on SQS if the argument is valid" do
      sqs = subject.send(:sqs)
      allow(sqs).to receive(:get_queue_url).with(queue_name: "concierge-test") {
        double(queue_url: "https://www.example.org/concierge-queue")
      }

      expect(sqs).to receive(:send_message).with({
        queue_url:    "https://www.example.org/concierge-queue",
        message_body: { operation: "sync", data: { key: "value" } }.to_json
      })

      subject.add(element)
    end
  end

  describe "#poll" do
    it "invokes the corresponding method from the SQS client" do
      sqs = subject.send(:sqs)
      allow(sqs).to receive(:get_queue_url).with(queue_name: "concierge-test") {
        double(queue_url: "https://www.example.org/concierge-queue")
      }

      poller = double
      expect(Aws::SQS::QueuePoller).to receive(:new).with("https://www.example.org/concierge-queue", client: sqs) { poller }
      expect(poller).to receive(:poll)

      subject.poll
    end

    context "message processing" do
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

      before do
        allow(subject).to receive(:queue_poller) { poller }
      end

      it "ensures that the result from the message processing block is a valid Result instance" do
        expect {
          subject.poll do
            42
          end
        }.to raise_error Workers::Queue::InvalidQueueProcessingResultError
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
end
