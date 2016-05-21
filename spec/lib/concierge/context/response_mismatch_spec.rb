require "spec_helper"

RSpec.describe Concierge::Context::ResponseMismatch do
  let(:params) {
    {
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
      expect(subject.to_h).to eq({
        type:    "response_mismatch",
        message: "Expected a non-null nightly rate",
        backtrace: [
          "lib/concierge/supplier/parser.rb:19 in get_rates",
          "lib/concierge/supplier/client/requester.rb:392 in perform_call"
        ]
      })
    end
  end
end
