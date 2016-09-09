require "spec_helper"

RSpec.describe RentalsUnited::Client do
  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:client) { described_class.new(credentials) }

  describe "#cancel" do
    let(:params) { { reference_number: '555444' } }

    it "calls cancel command class" do
      fetcher_class = RentalsUnited::Commands::Cancel

      expect_any_instance_of(fetcher_class).to(receive(:call))
      client.cancel(params)
    end
  end
end
