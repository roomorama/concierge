require 'spec_helper'

RSpec.describe Woori::Client do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:client) { described_class.new(credentials) }
  let(:params) { {} }

  describe "#quote" do
    it "calls quotation fetcher class" do
      fetcher_class = Woori::Commands::QuotationFetcher

      expect_any_instance_of(fetcher_class).to(receive(:call).with(params))
      client.quote(params)
    end
  end
end
