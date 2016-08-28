require "spec_helper"

RSpec.describe Woori::Repositories::File::Units do
  let(:import_files_path) { "spec/fixtures/woori/import_files" }
  let(:locations) { [Hanami.root.join(import_files_path, filename)] }
  let(:files) { locations.map { |location| File.new(location, 'r') } }
  let(:subject) { described_class.new(files) }

  context "when file is empty" do
    let(:filename) { "empty_bulk_roomtypes_0_to_10000.json" }

    describe "#all" do
      it "returns an empty array of units" do
        units = subject.all
        expect(units).to eq([])
      end
    end

    describe "#find" do
      it "returns nil" do
        unit_id = "111"
        unit = subject.find(unit_id)
        expect(unit).to eq(nil)
      end
    end

    describe "#find_all_by_property_id" do
      it "returns nil" do
        property_id = "111"
        units = subject.find_all_by_property_id(property_id)
        expect(units).to eq([])
      end
    end
  end

  context "when file is not empty" do
    let(:filename) { "bulk_roomtypes_0_to_10000.json" }

    describe "#all" do
      it "returns array of units" do
        units = subject.all
        expect(units.size).to eq(3)
        expect(units).to all(be_kind_of(Roomorama::Unit))
      end
    end

    describe "#find" do
      it "returns nil when there is no unit by given id" do
        unit_id = "111"
        unit = subject.find(unit_id)
        expect(unit).to eq(nil)
      end

      it "returns unit when unit is found by given id" do
        unit_id = "w_w0101533_R02"
        unit = subject.find(unit_id)
        expect(unit).to be_kind_of(Roomorama::Unit)
        expect(unit.identifier).to eq(unit_id)
      end
    end

    describe "#find_all_by_property_id" do
      it "returns units by given property id when there is no match" do
        property_id = "w_w0101534"
        units = subject.find_all_by_property_id(property_id)
        expect(units.size).to eq(0)
      end

      it "returns units by given property id when there is single match" do
        property_id = "w_w0101533"
        units = subject.find_all_by_property_id(property_id)
        expect(units.size).to eq(1)
        expect(units).to all(be_kind_of(Roomorama::Unit))
        expect(units.map(&:identifier)).to eq(["w_w0101533_R02"])
      end

      it "returns units by given property id when there is multiple matches" do
        property_id = "w_w0801017"
        units = subject.find_all_by_property_id(property_id)
        expect(units.size).to eq(2)
        expect(units).to all(be_kind_of(Roomorama::Unit))
        expect(units.map(&:identifier)).to eq(
          ["w_w0801017_R04", "w_w0801017_105"]
        )
      end
    end
  end
end
