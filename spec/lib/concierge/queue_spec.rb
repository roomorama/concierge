require "spec_helper"

RSpec.describe Concierge::Queue do
  let(:credentials) { Concierge::Credentials.for("sqs") }
  let(:element) { Concierge::Queue::Element.new(operation: "background_worker", data: { key: "value" }) }
  subject { described_class.new(credentials) }

  describe "#add" do
    it "denies invalid elements" do
      element = Concierge::Queue::Element.new(operation: nil, data: {})

      expect {
        subject.add(element)
      }.to raise_error Concierge::Queue::Element::InvalidOperationError
    end

    it "enqueues the message on SQS if the argument is valid" do
      sqs = subject.send(:sqs)
      allow(sqs).to receive(:get_queue_url).with(queue_name: "concierge-test") {
        double(queue_url: "https://www.example.org/concierge-queue")
      }

      expect(sqs).to receive(:send_message).with({
        queue_url:    "https://www.example.org/concierge-queue",
        message_body: { operation: "background_worker", data: { key: "value" } }.to_json
      })

      subject.add(element)
    end
  end
end
