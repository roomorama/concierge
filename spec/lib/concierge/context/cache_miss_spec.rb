require "spec_helper"

RSpec.describe Concierge::Context::CacheMiss do
  let(:params) {
    {
      key: "supplier.response",
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:      "cache_miss",
        timestamp: Time.now,
        key:       "supplier.response",
      })
    end
  end
end
