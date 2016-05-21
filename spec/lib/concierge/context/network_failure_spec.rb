require "spec_helper"

RSpec.describe Concierge::Context::NetworkFailure do
  let(:params) {
    {
      message: "Could not connect to supplier.com on port 80"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:      "network_failure",
        timestamp: Time.now,
        message:   "Could not connect to supplier.com on port 80"
      })
    end
  end
end
