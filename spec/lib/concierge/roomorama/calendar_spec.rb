require "spec_helper"

RSpec.describe Roomorama::Calendar do
  let(:entry_attributes) {
    {
      date:         "2016-05-22",
      available:    false,
      nightly_rate: 100
    }
  }

  let(:entry) { Roomorama::Calendar::Entry.new(entry_attributes) }
  let(:property_identifier) { "prop1" }

  subject { described_class.new(property_identifier) }

  describe "#add" do
    it "adds the entry to the list of calendar entries" do
      subject.add(entry)
      expect(subject.entries).to eq [entry]
    end
  end

  describe "#validate!" do
    it "raises an error in case there are invalid entries in the calendar" do
      subject.add(entry)
      subject.add(create_entry(nightly_rate: nil))

      expect {
        subject.validate!
      }.to raise_error(Roomorama::Calendar::ValidationError)
    end

    it "is valid if all entries are valid" do
      subject.add(entry)
      subject.add(create_entry(date: "2016-05-20"))

      expect(subject.validate!).to eq true
    end

    it "is valid if valid_stay_lengths is given as an array" do
      entry_attributes[:valid_stay_lengths] = [1, 7, 14]
      subject.add(entry)
      expect(subject.validate!).to eq true
    end
  end

  describe "#empty?" do
    it "is empty if no calendar entries are added" do
      expect(subject).to be_empty
    end

    it "is not empty if at least one calendar entry is added" do
      subject.add(entry)
      expect(subject).not_to be_empty
    end
  end

  describe "#to_h" do
    it "creates a representation of all entries given" do
      subject.add(create_entry(date: "2016-05-23", available: false, nightly_rate: 120))
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100))
      subject.add(create_entry(date: "2016-05-24", available: true,  nightly_rate: 150))

      expect(subject.to_h).to eq({
        identifier:        "prop1",
        start_date:        "2016-05-22",
        availabilities:    "101",
        nightly_prices:    [100, 120, 150]
      })
    end

    it "adds valid_stay_length field if at least one entry has the field" do
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100, valid_stay_lengths: [2]))
      subject.add(create_entry(date: "2016-05-23", available: false, nightly_rate: 120))
      subject.add(create_entry(date: "2016-05-24", available: true,  nightly_rate: 150))
      subject.add(create_entry(date: "2016-05-25", available: true,  nightly_rate: 150))
      subject.add(create_entry(date: "2016-05-26", available: true,  nightly_rate: 150))

      expect(subject.to_h).to eq({
        identifier:        "prop1",
        start_date:        "2016-05-22",
        availabilities:    "10111",
        nightly_prices:    [100, 120, 150, 150, 150],
        valid_stay_lengths: [[2], nil, nil, nil, nil]
      })
    end

    it "overwrites given weekly/monthly rates as well as check-in/check-out rules and minimum stays" do
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100, weekly_rate: 500, checkin_allowed: false))
      subject.add(create_entry(date: "2016-05-23", available: false, nightly_rate: 120, monthly_rate: 1000, checkin_allowed: true))
      subject.add(create_entry(date: "2016-05-24", available: true,  nightly_rate: 150, minimum_stay: 2, checkout_allowed: false))

      expect(subject.to_h).to eq({
        identifier:        "prop1",
        start_date:        "2016-05-22",
        availabilities:    "101",
        nightly_prices:    [100, 120, 150],
        weekly_prices:     [500, nil, nil],
        monthly_prices:    [nil, 1000, nil],
        minimum_stays:     [nil, nil, 2],
        checkin_allowed:   "011",
        checkout_allowed:  "110"
      })
    end

    it "fills in gaps in the given dates with approximations" do
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100))
      subject.add(create_entry(date: "2016-05-25", available: false, nightly_rate: 120))
      subject.add(create_entry(date: "2016-05-27", available: false,  nightly_rate: 150))

      average = (100 + 120 + 150) / 3

      expect(subject.to_h).to eq({
        identifier:        "prop1",
        start_date:        "2016-05-22",
        availabilities:    "111010",
        nightly_prices:    [100, average, average, 120, average, 150]
      })
    end

    it "is able to serialize empty calendars" do
      expect(subject.to_h).to eq({
        identifier:        "prop1",
        start_date:        "",
        availabilities:    "",
        nightly_prices:    []
      })
    end

    context "multi-unit support" do
      let(:unit_identifier) { "unit1" }
      let(:unit_calendar)   { described_class.new(unit_identifier) }

      before do
        subject.add(entry)
      end

      it "includes the calendars for each included unit" do
        unit_entry = create_entry(available: true, nightly_rate: 200)
        unit_calendar.add(unit_entry)

        subject.add_unit(unit_calendar)

        expect(subject.to_h).to eq({
          identifier:        "prop1",
          start_date:        "2016-05-22",
          availabilities:    "0",
          nightly_prices:    [100],

          units: [
            {
              identifier:        "unit1",
              start_date:        "2016-05-22",
              availabilities:    "1",
              nightly_prices:    [200]
            }
          ]
        })
      end
    end
  end

  def create_entry(overrides = {})
    Roomorama::Calendar::Entry.new(entry_attributes.merge(overrides))
  end
end
