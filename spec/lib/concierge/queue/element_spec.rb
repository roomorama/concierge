require "spec_helper"

RSpec.describe Concierge::Queue::Element do
  let(:operation) { "background_worker" }
  let(:data)      { { key: "value" } }

  subject { described_class.new(operation: operation, data: data) }

  describe "#validate!" do
    it "does not allow nil operations" do
      element = described_class.new(operation: nil, data: data)

      expect {
        element.validate!
      }.to raise_error Concierge::Queue::Element::InvalidOperationError
    end

    it "does not allow unrecognised operations" do
      element = described_class.new(operation: "invalid", data: data)

      expect {
        element.validate!
      }.to raise_error Concierge::Queue::Element::InvalidOperationError
    end

    it "accepts valid objects" do
      expect(subject.validate!).to eq true
    end
  end

  describe "#serialize" do
    it "returns a JSON representation of the operation" do
      expect(subject.serialize).to eq({ operation: operation, data: data }.to_json)
    end
  end
end
