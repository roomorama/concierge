require 'spec_helper'

module RentalsUnited
  RSpec.describe Dictionaries::Bedrooms do
    describe "#count_by_type_id" do
      it "returns bedrooms count by type id" do
        count = described_class.count_by_type_id("46")

        expect(count).to eq(23)
      end

      it "returns nil if property type was not found" do
        count = described_class.count_by_type_id("9999")

        expect(count).to eq(nil)
      end

      it "returns 0 for Studio" do
        count = described_class.count_by_type_id("1")

        expect(count).to eq(0)
      end
    end
  end
end
