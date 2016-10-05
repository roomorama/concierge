require 'spec_helper'

module RentalsUnited
  RSpec.describe Mappers::Calendar do
    let(:property_id) { "1234" }
    let(:seasons) do
      [
        RentalsUnited::Entities::Season.new(
          date_from: Date.parse("2016-09-01"),
          date_to:   Date.parse("2016-09-15"),
          price:     150.0
        ),
        RentalsUnited::Entities::Season.new(
          date_from: Date.parse("2016-10-01"),
          date_to:   Date.parse("2016-10-15"),
          price:     200.0
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
      result = mapper.build_calendar
      expect(result).to be_kind_of(Result)
      expect(result).to be_success

      calendar = result.value
      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
      expect(calendar.entries).to eq([])
    end

    it "builds calendar with entries" do
      mapper = described_class.new(property_id, seasons, availabilities)
      result = mapper.build_calendar
      expect(result).to be_kind_of(Result)
      expect(result).to be_success

      calendar = result.value
      expect(calendar.validate!).to eq(true)

      expect(calendar).to be_kind_of(Roomorama::Calendar)
      expect(calendar.identifier).to eq(property_id)
      expect(calendar.entries.size).to eq(2)
      expect(calendar.entries).to all(be_kind_of(Roomorama::Calendar::Entry))

      sep_entry = calendar.entries.find { |e| e.date.to_s == "2016-09-01" }
      expect(sep_entry.available).to eq(false)
      expect(sep_entry.minimum_stay).to eq(2)
      expect(sep_entry.nightly_rate).to eq(150.0)
      expect(sep_entry.checkin_allowed).to eq(true)
      expect(sep_entry.checkout_allowed).to eq(true)

      oct_entry = calendar.entries.find { |e| e.date.to_s == "2016-10-14" }
      expect(oct_entry.available).to eq(true)
      expect(oct_entry.minimum_stay).to eq(1)
      expect(oct_entry.nightly_rate).to eq(200.0)
      expect(sep_entry.checkin_allowed).to eq(true)
      expect(sep_entry.checkout_allowed).to eq(true)
    end

    it "keeps even not valid calendar entries setting nightly_rate to 0" do
      availabilities << RentalsUnited::Entities::Availability.new(
        date: Date.parse("2017-01-01"),
        available: true,
        minimum_stay: 5,
        changeover: 4
      )
      mapper = described_class.new(property_id, seasons, availabilities)
      result = mapper.build_calendar
      expect(result).to be_kind_of(Result)
      expect(result).to be_success

      calendar = result.value

      entry = calendar.entries.find { |e| e.date.to_s == "2017-01-01" }
      expect(entry.available).to eq(false)
      expect(entry.minimum_stay).to eq(5)
      expect(entry.nightly_rate).to eq(0.0)
      expect(entry.checkin_allowed).to eq(false)
      expect(entry.checkout_allowed).to eq(false)

      expect(calendar.validate!).to eq(true)
    end

    context "while availabilities changeover mapping" do
      let(:date) { Date.parse("2016-09-01") }
      let(:availabilities) do
        [
          RentalsUnited::Entities::Availability.new(
            date: date,
            available: false,
            minimum_stay: 2,
            changeover: changeover
          )
        ]
      end

      context "when changeover type id is 1" do
        let(:changeover) { 1 }

        it "sets checkin to be allowed and checkout to be denied" do
          mapper = described_class.new(property_id, seasons, availabilities)
          result = mapper.build_calendar
          expect(result).to be_kind_of(Result)
          expect(result).to be_success

          calendar = result.value
          expect(calendar.validate!).to eq(true)

          entry = calendar.entries.find { |e| e.date.to_s == date.to_s }
          expect(entry.checkin_allowed).to eq(true)
          expect(entry.checkout_allowed).to eq(false)
        end
      end

      context "when changeover type id is 2" do
        let(:changeover) { 2 }

        it "sets checkin to be denied and checkout to be allowed" do
          mapper = described_class.new(property_id, seasons, availabilities)
          result = mapper.build_calendar
          expect(result).to be_kind_of(Result)
          expect(result).to be_success

          calendar = result.value
          expect(calendar.validate!).to eq(true)

          entry = calendar.entries.find { |e| e.date.to_s == date.to_s }
          expect(entry.checkin_allowed).to eq(false)
          expect(entry.checkout_allowed).to eq(true)
        end
      end

      context "when changeover type id is 3" do
        let(:changeover) { 3 }

        it "sets both checkin and checkout to be denied" do
          mapper = described_class.new(property_id, seasons, availabilities)
          result = mapper.build_calendar
          expect(result).to be_kind_of(Result)
          expect(result).to be_success

          calendar = result.value
          expect(calendar.validate!).to eq(true)

          entry = calendar.entries.find { |e| e.date.to_s == date.to_s }
          expect(entry.checkin_allowed).to eq(false)
          expect(entry.checkout_allowed).to eq(false)
        end
      end

      context "when changeover type id is 4" do
        let(:changeover) { 4 }

        it "sets both checkin and checkout to be allowed" do
          mapper = described_class.new(property_id, seasons, availabilities)
          result = mapper.build_calendar
          expect(result).to be_kind_of(Result)
          expect(result).to be_success

          calendar = result.value
          expect(calendar.validate!).to eq(true)

          entry = calendar.entries.find { |e| e.date.to_s == date.to_s }
          expect(entry.checkin_allowed).to eq(true)
          expect(entry.checkout_allowed).to eq(true)
        end
      end

      context "when changeover type id is unknown" do
        let(:changeover) { 5 }

        it "returns not supported changeover error" do
          mapper = described_class.new(property_id, seasons, availabilities)
          result = mapper.build_calendar
          expect(result).not_to be_success
          expect(result.error.code).to eq(:not_supported_changeover)
        end
      end
    end
  end
end
