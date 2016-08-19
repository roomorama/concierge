require 'spec_helper'

RSpec.describe Woori::FileImporter do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_all_properties" do
    it "calls file property repository to load properties" do
      fetcher_class = Woori::Repositories::File::Properties

      expect_any_instance_of(fetcher_class).to(receive(:all))
      importer.fetch_all_properties
    end
  end

  describe "#fetch_all_units" do
    it "calls file unit repository to load units" do
      fetcher_class = Woori::Repositories::File::Units

      expect_any_instance_of(fetcher_class).to(receive(:all))
      importer.fetch_all_units
    end
  end

  describe "#fetch_all_property_units" do
    it "calls file unit repository to load units for properties" do
      fetcher_class = Woori::Repositories::File::Units
      property_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:find_all_by_property_id).with(property_id)
      )
      importer.fetch_all_property_units(property_id)
    end
  end
end
