require "spec_helper"

RSpec.describe Concierge::Context::NetworkResponse do
  let(:params) {
    {
      status:       "200",
      headers: {
        "Connection"   => "keep-alive",
        "Content-Type" => "application/xml"
      },
      body: "<status>OK</status>"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      expect(subject.to_h).to eq({
        type:   "network_response",
        status: "200",
        headers: {
          "Connection" => "keep-alive",
          "Content-Type" => "application/xml"
        },
        body: "<status>OK</status>"
      })
    end
  end
end
