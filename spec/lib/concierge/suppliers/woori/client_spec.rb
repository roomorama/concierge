require 'spec_helper'

RSpec.describe Woori::Client do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:client) { described_class.new(credentials) }

  describe "#quote" do
    let(:params) { {} }

    it "calls quotation fetcher class" do
      fetcher_class = Woori::Commands::QuotationFetcher

      expect_any_instance_of(fetcher_class).to(receive(:call).with(params))
      client.quote(params)
    end
  end

  describe "#cancel" do
    let(:params) { { reservation_id: '123' } }

    it "calls cancel command class" do
      fetcher_class = Woori::Commands::Cancel

      expect_any_instance_of(fetcher_class).to(receive(:call).with('123'))
      client.cancel(params)
    end
  end
end
