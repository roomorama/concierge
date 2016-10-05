require 'spec_helper'

module RentalsUnited
  RSpec.describe Dictionaries::Amenities do
    describe "#supported_amenities" do
      it "returns array of supported amenities" do
        expect(described_class.supported_amenities).to be_kind_of(Array)
        expect(described_class.supported_amenities).to all(be_kind_of(Hash))
      end
    end

    describe "#convert" do
      it "returns an emptry string when there is no given RU services" do
        service_ids = []

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq([])
      end

      it "returns an empty string when there is no any match in given RU services" do
        service_ids = ["8888", "9999"]

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq([])
      end

      it "converts RU services to amenities if there is a match" do
        service_ids = ["11", "74"]

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq(["laundry", "tv"])
      end

      it "skips unknown RU services and returns only amenities with matches" do
        service_ids = ["11", "74", "8888"]

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq(["laundry", "tv"])
      end

      it "removes duplicates if there are two RU services with the same name" do
        service_ids = ["89", "89", "89"]

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq(["balcony"])
      end

      it "removes duplicates if there are RU services with the same match" do
        service_ids = ["89", "96"]

        amenities = described_class.new(service_ids).convert
        expect(amenities).to eq(["balcony"])
      end
    end

    describe "#smoking_allowed?" do
      let(:service_ids) { ["89", "96"] }

      it "returns false when no smoking_allowed facilities are included" do
        smoking_allowed_ids = []
        ids = (service_ids + smoking_allowed_ids).flatten

        dictionary = described_class.new(ids)
        expect(dictionary).not_to be_smoking_allowed
      end

      it "returns true when one of smoking_allowed facilities is included" do
        smoking_allowed_ids = ["799", "802"]
        smoking_allowed_ids.each do |id|
          ids = (service_ids + [id]).flatten

          dictionary = described_class.new(ids)
          expect(dictionary).to be_smoking_allowed
        end
      end
    end

    describe "#pets_allowed?" do
      let(:service_ids) { ["89", "96"] }

      it "returns false when no pets_allowed facilities are included" do
        pets_allowed_ids = []
        ids = (service_ids + pets_allowed_ids).flatten

        dictionary = described_class.new(ids)
        expect(dictionary).not_to be_pets_allowed
      end

      it "returns true when one of pets_allowed facilities is included" do
        pets_allowed_ids = ["595"]
        pets_allowed_ids.each do |id|
          ids = (service_ids + [id]).flatten

          dictionary = described_class.new(ids)
          expect(dictionary).to be_pets_allowed
        end
      end
    end
  end
end
