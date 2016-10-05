require 'spec_helper'

module RentalsUnited
  RSpec.describe Entities::PropertiesCollection do
    let(:entries) do
      [
        { property_id: '10', location_id: '100' },
        { property_id: '20', location_id: '200' }
      ]
    end

    let(:collection) { described_class.new(entries) }
    let(:empty_collection) { described_class.new([]) }

    describe "size" do
      it "returns size of collection" do
        expect(collection.size).to eq(2)
      end

      it "returns size of empty collection" do
        expect(empty_collection.size).to eq(0)
      end
    end

    describe "#property_ids" do
      it "returns array with property ids of entries in collection" do
        expect(collection.property_ids).to eq(["10", "20"])
      end

      it "returns array with property ids of entries in empty collection" do
        expect(empty_collection.property_ids).to eq([])
      end
    end

    describe "#location_ids" do
      it "returns array with location ids of entries in collection" do
        expect(collection.location_ids).to eq(["100", "200"])
      end

      it "returns array with location ids of entries in empty collection" do
        expect(empty_collection.location_ids).to eq([])
      end

      context "with duplicate locations" do
        let(:entries) do
          [
            { property_id: '10', location_id: '100' },
            { property_id: '20', location_id: '100' }
          ]
        end

        it "returns array with uniq location ids of entries in collection" do
          expect(collection.location_ids).to eq(["100"])
        end
      end
    end
  end
end
