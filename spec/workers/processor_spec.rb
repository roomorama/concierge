require "spec_helper"

RSpec.describe Workers::Processor do
  include Support::Factories

  let(:json)    { payload.to_json }

  subject { described_class.new(json) }

  describe "#process! for background_worker" do
    let(:payload) { { operation: "background_worker", data: { background_worker_id: 2 } } }

    it "returns an invalid result if the given JSON element is malformed" do
      subject = described_class.new("invalid-json")
      result = subject.process!

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it "complains about unknown operations" do
      payload[:operation] = "invalid"

      expect {
        subject.process!
      }.to raise_error Workers::Processor::UnknownOperationError
    end

    it "processes background worker messages" do
      worker_processor = double

      expect(Workers::Processor::BackgroundWorker).to receive(:new).with(
        Concierge::SafeAccessHash.new({ "background_worker_id" => 2 })
      ).and_return(worker_processor)

      expect(worker_processor).to receive(:run)
      subject.process!
    end
  end

  describe "#process! for properties_push" do
    let(:payload) { { operation: "properties_push", data: [1, 2] } }
    it "processes the message" do
      worker_processor = double
      expect(Workers::Processor::PropertiesPush).to receive(:new).
        with([1, 2]).and_return(worker_processor)
      expect(worker_processor).to receive(:run)

      subject.process!
    end
  end
end
