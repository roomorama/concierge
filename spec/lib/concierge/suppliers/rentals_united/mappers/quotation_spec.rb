require "spec_helper"

RSpec.describe RentalsUnited::Mappers::Quotation do
  include Support::Factories

  context "when price exists" do
    let!(:host) { create_host(fee_percentage: 7.0) }
    let!(:property) { create_property(identifier: "567", host_id: host.id) }
    let(:price) { RentalsUnited::Entities::Price.new(total: 123.45, available: true) }
    let(:currency) { "USD" }
    let(:quotation_params) do
      API::Controllers::Params::Quote.new(
        property_id: property.identifier,
        check_in: "2016-09-19",
        check_out: "2016-09-20",
        guests: 3
      )
    end
    let(:subject) do
      described_class.new(
        price,
        currency,
        quotation_params
      )
    end

    it "builds quotation object" do
      quotation = subject.build_quotation
      expect(quotation).to be_kind_of(Quotation)
      expect(quotation.property_id).to eq(quotation_params[:property_id])
      expect(quotation.check_in).to eq(quotation_params[:check_in])
      expect(quotation.check_out).to eq(quotation_params[:check_out])
      expect(quotation.guests).to eq(quotation_params[:guests])
      expect(quotation.total).to eq(price.total)
      expect(quotation.available).to eq(price.available?)
      expect(quotation.currency).to eq(currency)
      expect(quotation.host_fee_percentage).to eq(7.0)
    end
  end
end
