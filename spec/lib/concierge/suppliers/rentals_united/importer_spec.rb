require "spec_helper"

RSpec.describe RentalsUnited::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_location_ids" do
    it "calls fetcher class to load location ids" do
      fetcher_class = RentalsUnited::Commands::LocationIdsFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_location_ids))
      importer.fetch_location_ids
    end
  end

  describe "#fetch_locations" do
    let(:location_ids) { ['10', '20', '30'] }

    it "calls fetcher class to load locations" do
      fetcher_class = RentalsUnited::Commands::LocationsFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_locations))
      importer.fetch_locations(location_ids)
    end
  end

  describe "#fetch_location_currencies" do
    it "calls fetcher class to load locations and currencies" do
      fetcher_class = RentalsUnited::Commands::LocationCurrenciesFetcher

      expect_any_instance_of(fetcher_class).to(
        receive(:fetch_location_currencies)
      )
      importer.fetch_location_currencies
    end
  end

  describe "#fetch_property_ids" do
    let(:location_id) { "1234" }

    it "calls fetcher class to load property ids" do
      fetcher_class = RentalsUnited::Commands::PropertyIdsFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_property_ids))
      importer.fetch_property_ids(location_id)
    end
  end

  describe "#fetch_property" do
    let(:property_id) { "588788" }

    it "calls fetcher class to load property" do
      fetcher_class = RentalsUnited::Commands::PropertyFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_property))
      importer.fetch_property(property_id)
    end
  end

  describe "#fetch_properties_by_ids" do
    let(:property_ids) { ["222", "333"] }

    it "calls #fetch_property for every property id" do
      property_ids.each do |id|
        expect_any_instance_of(described_class).to(
          receive(:fetch_property).with(id) { Result.new("success") }
        )
      end

      result = importer.fetch_properties_by_ids(property_ids)
      expect(result).to be_success
    end

    it "ignores nil results" do
      expect_any_instance_of(described_class).to(
        receive(:fetch_property).with("222") { Result.new("success") }
      )

      expect_any_instance_of(described_class).to(
        receive(:fetch_property).with("333") { Result.new(nil) }
      )

      result = importer.fetch_properties_by_ids(property_ids)
      expect(result).to be_success
      expect(result.value.size).to eq(1)
    end

    it "returns error if fetching property_id fails" do
      expect_any_instance_of(described_class).to(
        receive(:fetch_property).with("222") { Result.error("fail") }
      )

      result = importer.fetch_properties_by_ids(property_ids)
      expect(result).not_to be_success
    end

    it "returns error on fail even if previous fetchers returned success" do
      expect_any_instance_of(described_class).to(
        receive(:fetch_property).with("222") { Result.new("success") }
      )
      expect_any_instance_of(described_class).to(
        receive(:fetch_property).with("333") { Result.error("fail") }
      )

      result = importer.fetch_properties_by_ids(property_ids)
      expect(result).not_to be_success
    end
  end

  describe "#fetch_owners" do
    it "calls fetcher class to load owners" do
      fetcher_class = RentalsUnited::Commands::OwnersFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_owners))
      importer.fetch_owners
    end
  end
end
