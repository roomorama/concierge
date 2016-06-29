require "spec_helper"

RSpec.describe Calendar do
  subject { described_class.new(property_id: "A-123") }

  describe "#add" do
    it "is successful in case the entry is a Calendar::Entry instance" do
      entry = Calendar::Entry.new(date: "2016-05-22", available: false)
      subject.add(entry)

      expect(subject.entries).to eq [entry]
    end

    it "raises an error in case the entry passed is not a Calendar::Entry" do
      entry = Object.new

      expect {
        subject.add(entry)
      }.to raise_error(Calendar::InvalidEntryError)
    end
  end
end
