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

    let(:safe_hash) do
      Concierge::SafeAccessHash.new(property_hash)
    end

    it "sets id to the property" do
      property = described_class.build(safe_hash)
      expect(property.identifier).to eq(28271)
    end
    
    it "sets type to the property" do
      property = described_class.build(safe_hash)
      expect(property.type).to eq("property")
    end

    it "sets address information to the property" do
      property = described_class.build(safe_hash)
      expect(property.lat).to eq(37.7225)
      expect(property.lng).to eq(127.273)
      expect(property.address).to eq("Sudong-myeon, Namyangju-si, Gyeonggi-do 239-25, Cheolmasan-ro")
      expect(property.city).to eq("Namyangju-si")
    end

    it "sets proper currency" do
      property = described_class.build(safe_hash)
      expect(property.currency).to eq("KRW")
    end
    
    it "sets default_to_available flag" do
      property = described_class.build(safe_hash)
      expect(property.default_to_available).to eq(true)
    end
    
    it "sets multi-unit flag" do
      property = described_class.build(safe_hash)
      expect(property.multi_unit).to eq(true)
    end

    it "sets instant_booking flag" do
      property = described_class.build(safe_hash)
      expect(property.instant_booking?).to eq(true)
    end
    
    it "sets images if images are present" do
      property = described_class.build(safe_hash)
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(46)
      expect(property.images).to all(be_kind_of(Roomorama::Image))
    end
    
    it "keeps images empty images are not present" do
      property_hash["data"]["images"] = []
      property = described_class.build(safe_hash)
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
      
      property_hash["data"]["images"] = nil
      property = described_class.build(safe_hash)
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
      
      property_hash["data"].delete("images")
      property = described_class.build(safe_hash)
      expect(property.images).to be_kind_of(Array)
      expect(property.images.size).to eq(0)
    end
  end
end
