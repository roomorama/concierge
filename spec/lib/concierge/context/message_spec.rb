require "spec_helper"

RSpec.describe Concierge::Context::Message do
  let(:params) {
    {
      label:   "Parsing Failure",
      message: "Expected a non-null nightly rate",
      backtrace: [
        [Hanami.root.join("lib/concierge/supplier/parser.rb").to_s, ":19 in get_rates"].join,
        [Hanami.root.join("lib/concierge/supplier/client/requester.rb").to_s, ":392 in perform_call"].join,
        "/home/deploy/.rmv/rubies/unicorn/server.rb:1239 in process",
        "/home/deploy/.rmv/rubies/unicorn/server.rb:2 in run",
        "/home/deploy/.rmv/rubies/unicorn/server.rb:2309 in new"
      ]
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21", "16", "15", "42") }

      expect(subject.to_h).to eq({
        type:        "generic_message",
        timestamp:   Time.now,
        label:       "Parsing Failure",
        message:     "Expected a non-null nightly rate",
        backtrace:   [
          "lib/concierge/supplier/parser.rb:19 in get_rates",
          "lib/concierge/supplier/client/requester.rb:392 in perform_call"
        ],
        content_type: "plain"
      })
    end
  end
end
