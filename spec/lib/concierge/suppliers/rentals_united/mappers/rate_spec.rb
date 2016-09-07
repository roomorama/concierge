require 'spec_helper'

module RentalsUnited
  RSpec.describe Mappers::Rate do
    let(:rate_hash) do
      {
        "Price"=>"200.0000",
        "Extra"=>"10.0000",
        "@DateFrom"=>"2016-09-07",
        "@DateTo"=>"2016-09-30"
      }
    end

    it "builds rate object" do
      mapper = described_class.new(rate_hash)
      rate = mapper.build_rate

      expect(rate).to be_kind_of(RentalsUnited::Entities::Rate)
      expect(rate.date_from).to be_kind_of(Date)
      expect(rate.date_from.to_s).to eq("2016-09-07")
      expect(rate.date_to).to be_kind_of(Date)
      expect(rate.date_to.to_s).to eq("2016-09-30")
      expect(rate.price).to eq("200.0000")
    end
  end
end
