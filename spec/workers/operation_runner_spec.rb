require "spec_helper"

RSpec.describe Workers::OperationRunner do
  include Support::Factories

  let(:host) { create_host }
  subject { described_class.new(host) }

  describe "#perform" do
    it "performs publish calls" do
      roomorama_property = double(validate!: true)
      operation = Roomorama::Client::Operations.publish(roomorama_property)

      expect_any_instance_of(Workers::OperationRunner::Publish).to receive(:perform).with(roomorama_property) { Result.new(true) }
      subject.perform(operation, roomorama_property)
    end

    it "performs diff calls" do
      roomorama_property = double
      diff = double(validate!: true)
      operation = Roomorama::Client::Operations.diff(diff)

      expect_any_instance_of(Workers::OperationRunner::Diff).to receive(:perform).with(roomorama_property) { Result.new(true) }
      subject.perform(operation, roomorama_property)
    end

    it "performs disable calls" do
      identifiers = ["prop1"]
      operation   = Roomorama::Client::Operations.disable(identifiers)

      expect_any_instance_of(Workers::OperationRunner::Disable).to receive(:perform) { Result.new(true) }
      subject.perform(operation)
    end

    it "raises an error if the operation is not recognised" do
      operation = nil
      expect {
        subject.perform(operation)
      }.to raise_error Workers::OperationRunner::InvalidOperationError
    end
  end
end
