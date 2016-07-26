require 'spec_helper'

module Woori
  RSpec.describe Mappers::UnitRates do
    include Concierge::JSON
    include Support::Fixtures

    let(:unit_hash) do
      json = read_fixture("woori/unit_rates/success.json")
      result = json_decode(json)
      result.value
    end

    let(:safe_hash) { Concierge::SafeAccessHash.new(unit_hash) }
    let(:mapper) { described_class.new(safe_hash) }

    it "builds unit rates object" do
      unit_rate = mapper.build_unit_rates
      expect(unit_rate.nightly_rate).to eq(101333)
      expect(unit_rate.weekly_rate).to eq(709331)
      expect(unit_rate.monthly_rate).to eq(3040000)
    end

    it "returns nil if days is nil" do
      unit_hash["data"] = nil
      unit_rate = mapper.build_unit_rates

      expect(unit_rate).to be_nil
    end

    it "returns nil if days is empty" do
      unit_hash["data"] = []
      unit_rate = mapper.build_unit_rates

      expect(unit_rate).to be_nil
    end
  end
end
