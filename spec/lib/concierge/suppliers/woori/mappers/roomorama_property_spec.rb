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
  end
end
