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

    let(:safe_hash) do
      Concierge::SafeAccessHash.new(unit_hash)
    end

    it "sets id to the unit" do
      unit = described_class.build(safe_hash)
      expect(unit.identifier).to eq("w_w0104006_R05")
    end
    
    it "sets max_guests to the unit" do
      unit = described_class.build(safe_hash)
      expect(unit.max_guests).to eq(8)
    end
    
    it "sets amenities" do
      unit_hash["data"]["facilities"] = ["TV"]
      unit = described_class.build(safe_hash)

      expect(unit.amenities).to eq(["tv"])
    end

    it "skips unknown amenities" do
      unit_hash["data"]["facilities"] = ["TV", "foo", "bar"]
      unit = described_class.build(safe_hash)

      expect(unit.amenities).to eq(["tv"])
    end
    
    it "keeps amenities empty if there is not Woori facilities" do
      unit_hash["data"]["facilities"] = []
      unit = described_class.build(safe_hash)

      expect(unit.amenities).to eq([])
    end
    
    describe "changes description to include additional amenities" do
      it "keeps description as is when no amenities is present" do
        unit_hash["data"]["facilities"] = []
        unit = described_class.build(safe_hash)

        expect(unit.description).to eq("Test description")
      end
      
      it "keeps description as is when no additional amenities is present" do
        unit_hash["data"]["facilities"] = ["TV", "cookware", "air conditioner"]
        unit = described_class.build(safe_hash)

        expect(unit.description).to eq("Test description")
      end

      it "adds additional amenities to description" do
        unit_hash["data"]["facilities"] = ["foo", "bar"]
        unit = described_class.build(safe_hash)

        expect(unit.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end

      it "does not add double dot signs after description" do
        unit_hash["data"]["description"] = "Test description."
        unit_hash["data"]["facilities"] = ["foo", "bar"]
        unit = described_class.build(safe_hash)

        expect(unit.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end
      
      it "adds additional amenities to description ignoring known amenitites" do
        unit_hash["data"]["facilities"] = ["TV", "foo", "bar"]
        unit = described_class.build(safe_hash)

        expect(unit.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end
    
      it "adds additional amenities to description when description is blank" do
        variations = ["", " ", nil]

        variations.each do |desc|
          unit_hash["data"]["description"] = desc
          unit_hash["data"]["facilities"] = ["foo", "bar"]

          unit = described_class.build(safe_hash)

          expect(unit.description).to eq("Additional amenities: foo, bar")
        end
      end

      it "keeps description empty when there is no additional amenities and original description" do
        unit_hash["data"]["description"] = nil
        unit_hash["data"]["facilities"] = ["TV"]
          
        unit = described_class.build(safe_hash)

        expect(unit.description).to be_nil
      end
    end
  end
end
