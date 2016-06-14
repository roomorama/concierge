require "spec_helper"

RSpec.describe Concierge::Context::TokenReceived do
  let(:params) { {"token_type"=>"BEARER", "scope"=>"basic"} }
  let(:access_token) { "very_important_string" }
  let(:expires_at) { Time.now.to_i }

  subject { described_class.new(params: params,
                                access_token: access_token,
                                expires_at: expires_at) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:      "token_received",
        timestamp: Time.now,
        params:   params,
        access_token: "very...",
        expires_at:   Time.at(expires_at)
      })
    end
  end
end
