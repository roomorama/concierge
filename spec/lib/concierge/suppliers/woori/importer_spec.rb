require 'spec_helper'

RSpec.describe Woori::Importer do
  let(:credentials) { Concierge::Credentials.for("Woori") }
  let(:importer) { described_class.new(credentials) }

  describe "#fetch_unit_rates" do
    it "calls http unit rates repository to load properties" do
      fetcher_class = Woori::Commands::UnitRatesFetcher
      unit_id = "abcd"

      expect_any_instance_of(fetcher_class).to(
        receive(:find_rates).with(unit_id)
      )
      importer.fetch_unit_rates(unit_id)
    end
  end
end
