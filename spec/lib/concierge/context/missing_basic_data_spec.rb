require "spec_helper"

RSpec.describe Concierge::Context::MissingBasicData do
  let(:params) {
    {
      error_message: "Image validation error: identifier is not given",
      attributes:    { title: "Large Unit" }
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:          "missing_basic_data",
        timestamp:     Time.now,
        error_message: "Image validation error: identifier is not given",
        attributes:    { title: "Large Unit" }
      })
    end
  end
end
