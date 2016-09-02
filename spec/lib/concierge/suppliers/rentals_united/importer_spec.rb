require "spec_helper"

RSpec.describe RentalsUnited::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("rentals_united") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_cities" do
    it "calls fetcher class to load cities " do
      fetcher_class = RentalsUnited::Commands::CitiesFetcher

      expect_any_instance_of(fetcher_class).to(receive(:fetch_cities))
      importer.fetch_cities
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
end
