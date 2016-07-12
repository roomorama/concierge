require "spec_helper"

RSpec.describe Concierge::Context::SyncProcess do
  let(:params) {
    {
      worker:     "metadata",
      host_id:    2,
      identifier: "prop1"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:       "sync_process",
        worker:     "metadata",
        timestamp:  Time.now,
        host_id:    2,
        identifier: "prop1"
      })
    end
  end
end
