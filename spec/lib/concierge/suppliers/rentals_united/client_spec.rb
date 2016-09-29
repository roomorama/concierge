require "spec_helper"

RSpec.describe RentalsUnited::Client do
  include Support::Factories

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:client) { described_class.new(credentials) }

  describe "#quote" do
    let(:property) do
      create_property(identifier: '1234', data: { :currency => "USD" })
    end

    let(:quotation_params) do
      {
        property_id: property.identifier,
        check_in: '2016-02-02',
        check_out: '2016-02-03',
        guests: 2
      }
    end

    it "returns error if property does not exist" do
      quotation_params[:property_id] = "unknown"

      fetcher_class = RentalsUnited::Commands::QuotationFetcher
      expect_any_instance_of(fetcher_class).not_to(receive(:call))

      result = client.quote(quotation_params)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:property_not_found)
    end

    it "calls quotation fetcher class if property exists" do
      fetcher_class = RentalsUnited::Commands::QuotationFetcher
      expect_any_instance_of(fetcher_class).to(receive(:call))

      client.quote(quotation_params)
    end
  end
end
