require "spec_helper"

RSpec.describe Concierge::Context::JSONParsingError do
  let(:params) {
    {
      message: "Invalid syntax at 45:209"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:      "json_parsing_error",
        timestamp: Time.now,
        message:   "Invalid syntax at 45:209"
      })
    end
  end
end
