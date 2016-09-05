require 'spec_helper'

module Woori
  RSpec.describe Converters::Amenities do
    describe "#supported_amenities" do
      it "returns supported amenities hash" do
        converter = described_class.new([])
        expect(converter.supported_amenities).to be_kind_of(Hash)
      end
    end

    describe "#convert" do
      it "returns an empty array when there is no given woori services" do
        services = []
        amenities = described_class.new(services).convert
        expect(amenities).to eq([])
      end

      it "returns an empty array when there is no given woori services" do
        services = nil
        amenities = described_class.new(services).convert
        expect(amenities).to eq([])
      end

      it "returns an empty string when there is no any match in given woori services" do
        services = ["Foo", "Bar"]

        amenities = described_class.new(services).convert
        expect(amenities).to eq([])
      end

      it "converts woori services to amenities if there is a match" do
        services = ["internet", "free breakfast"]

        amenities = described_class.new(services).convert
        expect(amenities).to eq(["internet", "breakfast"])
      end

      it "skips unknown woori services and returns only amenities with matches" do
        services = ["cookware", "Foo", "TV"]

        amenities = described_class.new(services).convert
        expect(amenities).to eq(["kitchen", "tv"])
      end

      it "removes duplicates if there are two woori services with the same name" do
        services = ["cookware", "cookware", "TV"]

        amenities = described_class.new(services).convert
        expect(amenities).to eq(["kitchen", "tv"])
      end

      it "removes duplicates if there are woori services with the same match" do
        services = ["swimming pool - 15m", "swimming pool", "TV"]

        amenities = described_class.new(services).convert
        expect(amenities).to eq(["pool", "tv"])
      end
    end

    describe "#select_not_supported_amenities" do
      it "return [] if no saw_services were provided" do
        services = []

        amenities = described_class.new(services).select_not_supported_amenities
        expect(amenities).to eq([])
      end

      it "return [] if no saw_services were provided" do
        services = nil

        amenities = described_class.new(services).select_not_supported_amenities
        expect(amenities).to eq([])
      end

      it "return [] if all given amenitites has matches to Roomorama API" do
        services = ["TV", "internet", "cookware"]

        amenities = described_class.new(services).select_not_supported_amenities
        expect(amenities).to eq([])
      end

      it "finds amenities which has no matches to Roomorama API" do
        services = ["TV", "air conditioner", "Foo", "Bar"]

        amenities = described_class.new(services).select_not_supported_amenities
        expect(amenities).to eq(["Foo", "Bar"])
      end

      it "removes duplicate facility services" do
        services = ["cookware", "Foo", "Foo"]

        amenities = described_class.new(services).select_not_supported_amenities
        expect(amenities).to eq(["Foo"])
      end
    end
  end
end
