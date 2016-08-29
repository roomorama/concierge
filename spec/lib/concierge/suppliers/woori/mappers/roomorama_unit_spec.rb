require 'spec_helper'

module Woori
  RSpec.describe Mappers::RoomoramaUnit do
    include Concierge::JSON
    include Support::Fixtures

    let(:unit_hash) do
      json = read_fixture("woori/entities/unit/example.json")
      result = json_decode(json)
      result.value
    end

    let(:safe_hash) { Concierge::SafeAccessHash.new(unit_hash) }
    let(:mapper) { described_class.new(safe_hash) }

    it "sets id to the unit" do
      unit = mapper.build_unit
      expect(unit.identifier).to eq("w_w0104006_R05")
    end
    
    it "sets max_guests to the unit" do
      unit = mapper.build_unit
      expect(unit.max_guests).to eq(8)
    end

    it "sets number_of_bedrooms to the unit" do
      unit = mapper.build_unit
      expect(unit.number_of_bedrooms).to eq(1)
    end

    it "sets images if images are present" do
      unit = mapper.build_unit
      expect(unit.images).to be_kind_of(Array)
      expect(unit.images.size).to eq(8)
      expect(unit.images).to all(be_kind_of(Roomorama::Image))
    end

    it "keeps images empty when images attribute is an empty array" do
      unit_hash["data"]["images"] = []
      unit = mapper.build_unit
      expect(unit.images).to be_kind_of(Array)
      expect(unit.images.size).to eq(0)
    end

    it "keeps images empty when images attribute is nil" do
      unit_hash["data"]["images"] = nil
      unit = mapper.build_unit
      expect(unit.images).to be_kind_of(Array)
      expect(unit.images.size).to eq(0)
    end

    it "keeps images empty when images attribute is not present" do
      unit_hash["data"].delete("images")
      unit = mapper.build_unit
      expect(unit.images).to be_kind_of(Array)
      expect(unit.images.size).to eq(0)
    end

    it "sets amenities" do
      unit_hash["data"]["facilities"] = ["TV"]
      unit = mapper.build_unit

      expect(unit.amenities).to eq(["tv"])
    end

    it "skips unknown amenities" do
      unit_hash["data"]["facilities"] = ["TV", "foo", "bar"]
      unit = mapper.build_unit

      expect(unit.amenities).to eq(["tv"])
    end
    
    it "keeps amenities empty if there is not Woori facilities" do
      unit_hash["data"]["facilities"] = []
      unit = mapper.build_unit

      expect(unit.amenities).to eq([])
    end
  end
end
