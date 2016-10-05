require "spec_helper"

RSpec.describe RentalsUnited::Client do
  include Support::Factories

  let(:supplier_name) { RentalsUnited::Client::SUPPLIER_NAME }
  let(:credentials) { Concierge::Credentials.for(supplier_name) }
  let(:client) { described_class.new(credentials) }

  describe "#quote" do
    before do
      supplier = create_supplier(name: supplier_name)
      host = create_host(identifier: "ru-host", supplier_id: supplier.id)
      create_property(identifier: '1234', host_id: host.id, data: { :currency => "USD" })
    end

    let(:quotation_params) do
      {
        property_id: '1234',
        check_in: '2016-02-02',
        check_out: '2016-02-03',
        guests: 2
      }
    end

    it "returns error if property does not exist" do
      quotation_params[:property_id] = "unknown"

      fetcher_class = RentalsUnited::Commands::PriceFetcher
      expect_any_instance_of(fetcher_class).not_to(receive(:call))

      result = client.quote(quotation_params)
      expect(result.success?).to be false
      expect(result.error.code).to eq(:property_not_found)
    end

    it "calls price fetcher class if property exists" do
      price = RentalsUnited::Entities::Price.new(
        total: 123.45,
        available: true
      )

      fetcher_class = RentalsUnited::Commands::PriceFetcher
      expect_any_instance_of(fetcher_class)
        .to(receive(:call))
        .and_return(Result.new(price))

      result = client.quote(quotation_params)
      expect(result.success?).to be true

      quotation = result.value
      expect(quotation).to be_kind_of(Quotation)
    end
  end
end
