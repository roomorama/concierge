require 'spec_helper'

RSpec.describe SAW::Client do
  let(:credentials) { Concierge::Credentials.for("SAW") }
  let(:client) { described_class.new(credentials) }

  describe "#cancel" do
    let(:params) { { reference_number: '123' } }

    it "calls cancel command class" do
      fetcher_class = SAW::Commands::Cancel

      expect_any_instance_of(fetcher_class).to(receive(:call).with('123'))
      client.cancel(params)
    end
  end
end
