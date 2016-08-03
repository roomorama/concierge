require 'spec_helper'

RSpec.describe Woori::Importer do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_all_properties" do
    it "calls file property repository to load properties" do
      fetcher_class = Woori::Commands::PropertiesFetcher

      expect_any_instance_of(fetcher_class).to(receive(:load_all_properties))
      importer.fetch_all_properties
    end
  end

  describe "#fetch_all_units" do
    it "calls file unit repository to load units" do
      fetcher_class = Woori::Commands::UnitsFetcher

      expect_any_instance_of(fetcher_class).to(receive(:load_all_units))
      importer.fetch_all_units
    end
  end

  describe "#fetch_all_property_units" do
    it "calls file unit repository to load units for properties" do
      fetcher_class = Woori::Commands::UnitsFetcher
      property_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:find_all_by_property_id).with(property_id)
      )
      importer.fetch_all_property_units(property_id)
    end
  end

  describe "#fetch_unit_calendar" do
    it "calls fetcher class to load calendar" do
      fetcher_class = Woori::Commands::UnitCalendarFetcher
      unit_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:call).with(unit_id)
      )
      importer.fetch_unit_calendar(unit_id)
    end
  end
end
