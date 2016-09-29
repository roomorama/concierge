require "spec_helper"

RSpec.describe RentalsUnited::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_properties_collection_for_owner" do
    let(:owner_id) { "588788" }

    it "calls fetcher class to load properties collection" do
      fetcher_class = RentalsUnited::Commands::PropertiesCollectionFetcher

      expect_any_instance_of(fetcher_class).
        to(receive(:fetch_properties_collection_for_owner))
      importer.fetch_properties_collection_for_owner(owner_id)
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

  describe "#fetch_property" do
    let(:property_id) { "588788" }

    it "calls fetcher class to load property" do
      fetcher_class = RentalsUnited::Commands::PropertyFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_property))
      importer.fetch_property(property_id)
    end
  end

  describe "#fetch_owner" do
    let(:owner_id) { "123" }

    it "calls fetcher class to load owners" do
      fetcher_class = RentalsUnited::Commands::OwnerFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_owner))
      importer.fetch_owner(owner_id)
    end
  end

  describe "#fetch_availabilities" do
    let(:property_id) { "588788" }

    it "calls fetcher class to load availabilities" do
      fetcher_class = RentalsUnited::Commands::AvailabilitiesFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_availabilities))
      importer.fetch_availabilities(property_id)
    end
  end

  describe "#fetch_seasons" do
    let(:property_id) { "588788" }

    it "calls fetcher class to load availabilities" do
      fetcher_class = RentalsUnited::Commands::SeasonsFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_seasons))
      importer.fetch_seasons(property_id)
    end
  end
end
