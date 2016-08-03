require 'spec_helper'

RSpec.describe Woori::Importer do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_properties" do
    it "calls http property repository to load properties" do
      fetcher_class = Woori::Repositories::HTTP::Properties
      updated_at = "1970-01-01"
      limit = 50
      offset = 0

      expect_any_instance_of(fetcher_class).to(
        receive(:load_updates).with(updated_at, limit, offset)
      )
      importer.fetch_properties(updated_at, limit, offset)
    end
  end

  describe "#fetch_units" do
    it "calls http unit repository to load properties" do
      fetcher_class = Woori::Repositories::HTTP::Units
      property_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:find_all_by_property_id).with(property_id)
      )
      importer.fetch_all_property_units(property_id)
    end
  end

  describe "#fetch_unit_rates" do
    it "calls http unit rates repository to load properties" do
      fetcher_class = Woori::Repositories::HTTP::UnitRates
      unit_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:find_rates).with(unit_id)
      )
      importer.fetch_unit_rates(unit_id)
    end
  end
end
