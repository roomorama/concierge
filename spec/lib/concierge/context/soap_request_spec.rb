require "spec_helper"

RSpec.describe Concierge::Context::SOAPRequest do
  let(:params) {
    {
      endpoint:  "https://www.jtb.com/Hotel_Avail",
      operation: :gby010,
      payload:   "request_body"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:      "soap_request",
        timestamp: Time.now,
        endpoint:  "https://www.jtb.com/Hotel_Avail",
        operation: :gby010,
        payload:   "request_body"
      })
    end
  end
end
