require 'spec_helper'

module SAW
  RSpec.describe Converters::Amenities do
    describe "#supported_amenities" do
      it "returns supported amenities hash" do
        expect(described_class.supported_amenities).to be_kind_of(Hash)
      end
    end

    describe "#convert" do
      it "returns an emptry string when there is no given saw services" do
        saw_services = []

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq([])
      end

      it "returns an empty string when there is no any match in given saw services" do
        saw_services = ["Foo", "Bar"]

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq([])
      end

      it "converts saw services to amenities if there is a match" do
        saw_services = ["Broadband", "Parking (on site)"]

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq(["internet", "parking"])
      end

      it "skips unknown saw services and returns only amenities with matches" do
        saw_services = ["Broadband", "Foo", "Parking (on site)"]

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq(["internet", "parking"])
      end
      
      it "removes duplicates if there are two saw services with the same name" do
        saw_services = ["Broadband", "Broadband", "Parking (on site)"]

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq(["internet", "parking"])
      end
      
      it "removes duplicates if there are saw services with the same match" do
        saw_services = ["WIFI Chargeable", "WIFI Free of Charge", "Parking (on site)"]

        amenities = described_class.convert(saw_services)
        expect(amenities).to eq(["wifi", "parking"])
      end
    end

    describe "#select_not_supported_amenities" do
      it "return [] if no saw_services were provided" do
        services = []

        amenities = described_class.select_not_supported_amenities(services)
        expect(amenities).to eq([])
      end
      
      it "return [] if all given amenitites has matches to Roomorama API" do
        services = ["WIFI Chargeable", "WIFI Free of Charge", "Parking (on site)"]

        amenities = described_class.select_not_supported_amenities(services)
        expect(amenities).to eq([])
      end

      it "finds amenities which has no matches to Roomorama API" do
        services = ["WIFI Chargeable", "Foo", "Bar"]

        amenities = described_class.select_not_supported_amenities(services)
        expect(amenities).to eq(["Foo", "Bar"])
      end
      
      it "removes duplicate facility services" do
        services = ["WIFI Chargeable", "Foo", "Foo"]

        amenities = described_class.select_not_supported_amenities(services)
        expect(amenities).to eq(["Foo"])
      end
    end
  end
end
