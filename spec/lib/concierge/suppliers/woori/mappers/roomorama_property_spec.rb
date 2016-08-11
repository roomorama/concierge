require 'spec_helper'

module Woori
  RSpec.describe Mappers::RoomoramaProperty do
    include Concierge::JSON
    include Support::Fixtures

    let(:property_hash) do
      json = read_fixture("woori/entities/property/example.json")
      result = json_decode(json)
      result.value
    end

    let(:safe_hash) { Concierge::SafeAccessHash.new(property_hash) }
    let(:mapper) { described_class.new(safe_hash) }

    it "sets id to the property" do
      property = mapper.build_property
      expect(property.identifier).to eq("w_w0104006")
    end
    
    it "sets type to the property" do
      property = mapper.build_property
      expect(property.type).to eq("apartment")
    end

    it "sets address information to the property" do
      property = mapper.build_property
      expect(property.lat).to eq(37.7225)
      expect(property.lng).to eq(127.273)
      expect(property.address).to eq("Sudong-myeon, Namyangju-si, Gyeonggi-do 239-25, Cheolmasan-ro")
      expect(property.city).to eq("Namyangju-si")
      expect(property.neighborhood).to eq("Gyeonggi-do")
      expect(property.postal_code).to eq("12027")
    end

    it "sets proper currency" do
      property = mapper.build_property
      expect(property.currency).to eq("KRW")
    end
    
    it "sets country code" do
      property = mapper.build_property
      expect(property.country_code).to eq("KR")
    end
    
    it "sets default_to_available flag" do
      property = mapper.build_property
      expect(property.default_to_available).to eq(true)
    end
    
    it "sets multi-unit flag" do
      property = mapper.build_property
      expect(property.multi_unit).to eq(true)
    end

    it "sets instant_booking flag" do
      property = mapper.build_property
      expect(property.instant_booking?).to eq(true)
    end

    it "sets cancellation policy" do
      property = mapper.build_property
      expect(property.cancellation_policy).to eq('moderate')
    end

    it "sets minimum_stay" do
      property = mapper.build_property
      expect(property.minimum_stay).to eq(1)
    end

    it "sets check_in_time and check_out_time attributes" do
      property = mapper.build_property
      expect(property.check_in_time).to eq("15:00:00")
      expect(property.check_out_time).to eq("12:00:00")
    end
    
    it "sets images if images are present" do
      property = mapper.build_property
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(46)
      expect(property.images).to all(be_kind_of(Roomorama::Image))
    end
    
    it "keeps images empty images are not present" do
      property_hash["data"]["images"] = []
      property = mapper.build_property
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
      
      property_hash["data"]["images"] = nil
      property = mapper.build_property
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
      
      property_hash["data"].delete("images")
      property = mapper.build_property
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
    end

    it "sets amenities" do
      property_hash["data"]["facilities"] = ["TV", "swimming_pool"]
      property = mapper.build_property

      expect(property.amenities).to eq(["tv"])
    end

    it "skips unknown amenities" do
      property_hash["data"]["facilities"] = ["TV", "foo", "bar"]
      property = mapper.build_property

      expect(property.amenities).to eq(["tv"])
    end
    
    it "keeps amenities empty if there is not Woori facilities" do
      property_hash["data"]["facilities"] = []
      property = mapper.build_property

      expect(property.amenities).to eq([])
    end
  
    describe "changes description to include additional amenities" do
      it "keeps description as is when no amenities is present" do
        property_hash["data"]["facilities"] = []
        property = mapper.build_property

        expect(property.description).to eq("Test description")
      end
      
      it "keeps description as is when no additional amenities is present" do
        property_hash["data"]["facilities"] = ["TV", "cookware", "air conditioner"]
        property = mapper.build_property

        expect(property.description).to eq("Test description")
      end

      it "adds additional amenities to description" do
        property_hash["data"]["facilities"] = ["foo", "bar"]
        property = mapper.build_property

        expect(property.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end

      it "does not add double dot signs after description" do
        property_hash["data"]["description"] = "Test description."
        property_hash["data"]["facilities"] = ["foo", "bar"]
        property = mapper.build_property

        expect(property.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end
      
      it "adds additional amenities to description ignoring known amenitites" do
        property_hash["data"]["facilities"] = ["TV", "foo", "bar"]
        property = mapper.build_property

        expect(property.description).to eq(
          "Test description. Additional amenities: foo, bar"
        )
      end
    
      it "adds additional amenities to description when description is blank" do
        variations = ["", " ", nil]

        variations.each do |desc|
          property_hash["data"]["description"] = desc
          property_hash["data"]["facilities"] = ["foo", "bar"]

          property = mapper.build_property

          expect(property.description).to eq("Additional amenities: foo, bar")
        end
      end

      it "keeps description empty when there is no additional amenities and original description" do
        property_hash["data"]["description"] = nil
        property_hash["data"]["facilities"] = ["TV"]
          
        property = mapper.build_property

        expect(property.description).to be_nil
      end
    end
  end
end
