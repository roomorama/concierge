require 'spec_helper'

RSpec.describe Woori::Importer do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_properties" do
    it "calls fetcher class to load properties" do
      fetcher_class = Woori::Commands::PropertiesFetcher
      updated_at = "1970-01-01"
      limit = 50
      offset = 0

      expect_any_instance_of(fetcher_class).to(
        receive(:call).with(updated_at, limit, offset)
      )
      importer.fetch_properties(updated_at, limit, offset)
    end
  end

  describe "#fetch_units" do
    it "calls fetcher class to load properties" do
      fetcher_class = Woori::Commands::UnitsFetcher
      property_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:call).with(property_id)
      )
      importer.fetch_units(property_id)
    end
  end

  describe "#fetch_unit_rates" do
    it "calls fetcher class to load properties" do
      fetcher_class = Woori::Commands::UnitRatesFetcher
      unit_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:call).with(unit_id)
      )
      importer.fetch_unit_rates(unit_id)
    end
  end
end
