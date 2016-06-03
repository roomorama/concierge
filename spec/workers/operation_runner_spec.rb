require "spec_helper"

RSpec.describe Workers::OperationRunner do
  include Support::Factories

  let(:host) { create_host }

  describe "#perform" do
    it "performs publish calls" do
      roomorama_property = double(validate!: true, require_calendar!: true)
      operation = Roomorama::Client::Operations.publish(roomorama_property)

      expect_any_instance_of(Workers::OperationRunner::Publish).to receive(:perform).with(roomorama_property)
      described_class.new(host).perform(operation, roomorama_property)
    end

    it "performs diff calls" do
      roomorama_property = double
      diff = double(validate!: true)
      operation = Roomorama::Client::Operations.diff(diff)

      expect_any_instance_of(Workers::OperationRunner::Diff).to receive(:perform).with(roomorama_property)
      described_class.new(host).perform(operation, roomorama_property)
    end

    it "performs disable calls" do
      identifiers = ["prop1"]
      operation = Roomorama::Client::Operations.disable(identifiers)

      expect_any_instance_of(Workers::OperationRunner::Disable).to receive(:perform)
      described_class.new(host).perform(operation)
    end

    it "raises an error if the operation is not recognised" do
      operation = nil
      expect {
        described_class.new(host).perform(operation)
      }.to raise_error Workers::OperationRunner::InvalidOperationError
    end
  end
end
