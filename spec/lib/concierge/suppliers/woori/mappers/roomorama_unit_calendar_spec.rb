require 'spec_helper'

module Woori
  RSpec.describe Mappers::RoomoramaUnitCalendar do
    include Concierge::JSON
    include Support::Fixtures

    let(:calendar_data) do
      json = read_fixture("woori/unit_rates/success.json")
      result = json_decode(json)
      result.value
    end

    let(:unit_id) { "123" }
    let(:safe_hash) { Concierge::SafeAccessHash.new(calendar_data) }
    let(:mapper) { described_class.new(unit_id, safe_hash) }

    it "builds calendar object with its entries" do
      calendar = mapper.build_calendar
      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.identifier).to eq(unit_id)

      entries = calendar.entries
      expect(entries.size).to eq(30)
      expect(entries).to all(be_kind_of(Roomorama::Calendar::Entry))
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

    context "builds correct calendar entries" do
      let(:calendar_data) do
        json = read_fixture("woori/unit_rates/success_entry_available.json")
        result = json_decode(json)
        result.value
      end

      it "sets correct date" do
        calendar = mapper.build_calendar

        expect(calendar).to be_kind_of(Roomorama::Calendar)
        entries = calendar.entries

        expect(entries.size).to eq(1)
        expect(entries.first.date.to_s).to eq("2016-08-15")
      end

      it "sets correct entry price" do
        calendar = mapper.build_calendar

        expect(calendar).to be_kind_of(Roomorama::Calendar)
        entries = calendar.entries

        expect(entries.size).to eq(1)
        expect(entries.first.nightly_rate).to eq(80000.0)
      end
    end

    context "when entry is active and have vacancy" do
      let(:calendar_data) do
        json = read_fixture("woori/unit_rates/success_entry_available.json")
        result = json_decode(json)
        result.value
      end

      it "sets available to true" do
        calendar = mapper.build_calendar

        expect(calendar).to be_kind_of(Roomorama::Calendar)
        entries = calendar.entries

        expect(entries.size).to eq(1)
        expect(entries.first.available).to be true
      end
    end

    context "when entry is not active" do
      let(:calendar_data) do
        json = read_fixture("woori/unit_rates/success_entry_not_active.json")
        result = json_decode(json)
        result.value
      end

      it "sets available to false" do
        calendar = mapper.build_calendar

        expect(calendar).to be_kind_of(Roomorama::Calendar)
        entries = calendar.entries

        expect(entries.size).to eq(1)
        expect(entries.first.available).to be false
      end
    end

    context "when entry has no vacancy" do
      let(:calendar_data) do
        json = read_fixture("woori/unit_rates/success_entry_no_vacancy.json")
        result = json_decode(json)
        result.value
      end

      it "sets available to false" do
        calendar = mapper.build_calendar

        expect(calendar).to be_kind_of(Roomorama::Calendar)
        entries = calendar.entries

        expect(entries.size).to eq(1)
        expect(entries.first.available).to be false
      end
    end
  end
end
