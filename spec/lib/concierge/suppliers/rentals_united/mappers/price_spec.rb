require "spec_helper"

RSpec.describe RentalsUnited::Mappers::Price do
  context "when price exists" do
    let(:value) { 123.50 }
    let(:subject) { described_class.new(value) }

    it "builds price object" do
      price = subject.build_price
      expect(price).to be_kind_of(RentalsUnited::Entities::Price)
      expect(price.total).to eq(value)
      expect(price.available?).to be true
    end
  end

  context "when price does not exist" do
    [nil, ""].each do |value|
      let(:subject) { described_class.new(value) }

      it "builds price object" do
        price = subject.build_price
        expect(price).to be_kind_of(RentalsUnited::Entities::Price)
        expect(price.total).to eq(0.0)
        expect(price.available?).to be false
      end
    end
  end
end
