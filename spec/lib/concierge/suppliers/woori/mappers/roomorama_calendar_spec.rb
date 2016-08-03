require 'spec_helper'

module Woori
  RSpec.describe Mappers::RoomoramaCalendar do
    include Concierge::JSON
    include Support::Fixtures

    let(:calendar_data) do
      json = read_fixture("woori/unit_rates/success.json")
      result = json_decode(json)
      result.value
    end

    let(:safe_hash) { Concierge::SafeAccessHash.new(calendar_data) }
    let(:mapper) { described_class.new(safe_hash) }

    it "builds calendar object" do
      calendar = mapper.build_calendar
      expect(calendar.entries).not_to eq([])
    end

    it "returns nil if days is nil" do
      calendar_data["data"] = nil
      calendar = mapper.build_calendar

      expect(calendar).to be_nil
    end

    it "returns nil if days is empty" do
      calendar_data["data"] = []
      calendar = mapper.build_calendar

      expect(calendar).to be_nil
    end
  end
end
