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
  end
end
