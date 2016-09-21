require 'spec_helper'

module RentalsUnited
  RSpec.describe Mappers::Season do
    let(:season_hash) do
      {
        "Price"=>"200.0000",
        "Extra"=>"10.0000",
        "@DateFrom"=>"2016-09-07",
        "@DateTo"=>"2016-09-30"
      }
    end

    it "builds season object" do
      mapper = described_class.new(season_hash)
      season = mapper.build_season

      expect(season).to be_kind_of(RentalsUnited::Entities::Season)
      expect(season.date_from).to be_kind_of(Date)
      expect(season.date_from.to_s).to eq("2016-09-07")
      expect(season.date_to).to be_kind_of(Date)
      expect(season.date_to.to_s).to eq("2016-09-30")
      expect(season.price).to eq("200.0000")
    end
  end
end
