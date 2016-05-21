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
      expect(subject.to_h).to eq({
        type:    "network_failure",
        message: "Could not connect to supplier.com on port 80"
      })
    end
  end
end
