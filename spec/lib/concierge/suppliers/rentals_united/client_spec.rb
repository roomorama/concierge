require "spec_helper"

RSpec.describe RentalsUnited::Client do
  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:client) { described_class.new(credentials) }

  describe "#book" do
    let(:params) { {} }

    it "calls quotation fetcher class" do
      fetcher_class = RentalsUnited::Commands::Booking

      expect_any_instance_of(fetcher_class).to(receive(:call))
      client.book(params)
    end
  end
end
       
