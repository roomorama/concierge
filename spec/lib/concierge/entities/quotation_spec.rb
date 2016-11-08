require "spec_helper"

RSpec.describe Quotation do
  include Support::Factories

  let(:supplier) { create_supplier }
  let(:host) { create_host(fee_percentage: 5, supplier_id: supplier.id) }
  let!(:property) { create_property(identifier: '38180', host_id: host.id) }
  let(:subject) { described_class.new({ property_id: property.identifier, total: 1000 }) }

  describe "#host_fee_percentage" do
    it "returns host fee percentage" do
      expect(subject.host_fee_percentage).to eq(5)
    end
  end

  describe "#net_rate" do
    it "calc price without host fee" do
      expect(subject.net_rate).to eq(950.0)
    end
  end

  describe "#host fee" do
    it "returns host fee" do
      expect(subject.host_fee).to eq(50.0)
    end
  end

  describe "property" do
    it "returns quotation's property" do
      quotation_property = subject.property
      expect(quotation_property.identifier).to eq('38180')
      expect(quotation_property.host_id).to eq(host.id)
    end
  end
end
