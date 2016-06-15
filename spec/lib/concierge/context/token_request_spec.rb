require "spec_helper"

RSpec.describe Concierge::Context::TokenRequest do
  let(:site) { "https://test_site.com" }
  let(:client_id) { "test_id" }
  let(:client_secret) { "test_secret" }
  let(:strategy) { "client_credentials" }
  subject { described_class.new(site: site,
                                client_id: client_id,
                                client_secret: client_secret,
                                strategy: strategy) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:          "token_request",
        timestamp:     Time.now,
        site:          site,
        client_id:     "test...",
        client_secret: "test...",
        strategy:      strategy
      })
    end
  end
end
