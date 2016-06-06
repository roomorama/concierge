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
  end
end
