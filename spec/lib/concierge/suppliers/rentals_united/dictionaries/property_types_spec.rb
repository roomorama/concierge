require 'spec_helper'

module RentalsUnited
  RSpec.describe Dictionaries::PropertyTypes do
    describe "#find" do
      it "returns property type by its id" do
        property_type = described_class.find("35")

        expect(property_type).to be_kind_of(
          RentalsUnited::Entities::PropertyType
        )
        expect(property_type.id).to eq("35")
        expect(property_type.name).to eq("Villa")
        expect(property_type.roomorama_name).to eq("house")
        expect(property_type.roomorama_subtype_name).to eq("villa")
      end

      it "returns nil if property type was not found" do
        property_type = described_class.find("3500")

        expect(property_type).to be_nil
      end

      it "returns nil if property type was found but has no mapping to Roomorama" do
        property_type = described_class.find("20")

        expect(property_type).to be_nil
      end
    end

    describe "#all" do
      it "returns all property types" do
        property_types = described_class.all

        expect(property_types.size).to eq(12)
        expect(property_types).to all(
          be_kind_of(RentalsUnited::Entities::PropertyType)
        )
      end
    end
  end
end
