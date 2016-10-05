require 'spec_helper'

module RentalsUnited
  RSpec.describe Mappers::Availability do
    let(:availability_hash) do
      {
        "IsBlocked"=>true,
        "MinStay"=>"1",
        "Changeover"=>"4",
        "@Date"=>"2016-09-07"
      }
    end

    it "builds availability object" do
      mapper = described_class.new(availability_hash)
      availability = mapper.build_availability

      expect(availability).to be_kind_of(RentalsUnited::Entities::Availability)
      expect(availability.date).to be_kind_of(Date)
      expect(availability.date.to_s).to eq("2016-09-07")
      expect(availability.available).to eq(false)
      expect(availability.minimum_stay).to eq(1)
      expect(availability.changeover).to eq(4)
    end
  end
end
