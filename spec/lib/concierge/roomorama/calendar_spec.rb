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
  end

  describe "#to_h" do
    it "creates a representation of all entries given" do
      subject.add(create_entry(date: "2016-05-23", available: false, nightly_rate: 120))
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100))
      subject.add(create_entry(date: "2016-05-24", available: true,  nightly_rate: 150))

      expect(subject.to_h).to eq({
        identifier:       "prop1",
        start_date:       "2016-05-22",
        availabilities:   "101",
        nightly_rates:    [100, 120, 150],
        weekly_rates:     [nil, nil, nil],
        monthly_rates:    [nil, nil, nil],
        checkin_allowed:  "111",
        checkout_allowed: "111"
      })
    end

    it "overwrites given weekly/monthly rates as well as check-in/check-out rules" do
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100, weekly_rate: 500, checkin_allowed: false))
      subject.add(create_entry(date: "2016-05-23", available: false, nightly_rate: 120, monthly_rate: 1000, checkin_allowed: true))
      subject.add(create_entry(date: "2016-05-24", available: true,  nightly_rate: 150, checkout_allowed: false))

      expect(subject.to_h).to eq({
        identifier:       "prop1",
        start_date:       "2016-05-22",
        availabilities:   "101",
        nightly_rates:    [100, 120, 150],
        weekly_rates:     [500, nil, nil],
        monthly_rates:    [nil, 1000, nil],
        checkin_allowed:  "011",
        checkout_allowed: "110"
      })
    end

    it "fills in gaps in the given dates with approximations" do
      subject.add(create_entry(date: "2016-05-22", available: true,  nightly_rate: 100))
      subject.add(create_entry(date: "2016-05-25", available: false, nightly_rate: 120))
      subject.add(create_entry(date: "2016-05-27", available: false,  nightly_rate: 150))

      average = (100 + 120 + 150) / 3

      expect(subject.to_h).to eq({
        identifier:       "prop1",
        start_date:       "2016-05-22",
        availabilities:   "111010",
        nightly_rates:    [100, average, average, 120, average, 150],
        weekly_rates:     [nil, nil, nil, nil, nil, nil],
        monthly_rates:    [nil, nil, nil, nil, nil, nil],
        checkin_allowed:  "111111",
        checkout_allowed: "111111"
      })
    end
  end

  def create_entry(overrides = {})
    Roomorama::Calendar::Entry.new(entry_attributes.merge(overrides))
  end
end
