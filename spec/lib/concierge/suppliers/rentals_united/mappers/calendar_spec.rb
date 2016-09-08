require 'spec_helper'

module RentalsUnited
  RSpec.describe Mappers::Calendar do
    let(:property_id) { "1234" }
    let(:rates) do
      [
        RentalsUnited::Entities::Rate.new(
          date_from: Date.parse("2016-09-01"),
          date_to:   Date.parse("2016-09-15"),
          price:     "150.00"
        ),
        RentalsUnited::Entities::Rate.new(
          date_from: Date.parse("2016-10-01"),
          date_to:   Date.parse("2016-10-15"),
          price:     "200.00"
        )
      ]
    end

    let(:availabilities) do
      [
        RentalsUnited::Entities::Availability.new(
          date: Date.parse("2016-09-01"),
          available: false,
          minimum_stay: 2,
          changeover: 4
        ),
        RentalsUnited::Entities::Availability.new(
          date: Date.parse("2016-10-14"),
          available: true,
          minimum_stay: 1,
          changeover: 4
        )
      ]
    end

    it "builds empty property calendar" do
      mapper = described_class.new(property_id, [], [])
      calendar = mapper.build_calendar

      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
      expect(calendar.entries).to eq([])
    end

    it "builds calendar with entries" do
      mapper = described_class.new(property_id, rates, availabilities)
      calendar = mapper.build_calendar

      expect(calendar.validate!).to eq(true)

      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
      expect(calendar.entries.size).to eq(2)
      expect(calendar.entries).to all(be_kind_of(Roomorama::Calendar::Entry))

      sep_entry = calendar.entries.find { |e| e.date.to_s == "2016-09-01" }
      expect(sep_entry.available).to eq(false)
      expect(sep_entry.minimum_stay).to eq(2)
      expect(sep_entry.nightly_rate).to eq("150.00")

      oct_entry = calendar.entries.find { |e| e.date.to_s == "2016-10-14" }
      expect(oct_entry.available).to eq(true)
      expect(oct_entry.minimum_stay).to eq(1)
      expect(oct_entry.nightly_rate).to eq("200.00")
    end

    it "keeps only calendar entries which have prices" do
      availabilities << RentalsUnited::Entities::Availability.new(
        date: Date.parse("2017-01-01"),
        available: true,
        minimum_stay: 5,
        changeover: 4
      )
      mapper = described_class.new(property_id, rates, availabilities)
      calendar = mapper.build_calendar

      entry = calendar.entries.find { |e| e.date.to_s == "2017-01-01" }
      expect(entry).to be_nil

      expect(calendar.validate!).to eq(true)
    end
  end
end
