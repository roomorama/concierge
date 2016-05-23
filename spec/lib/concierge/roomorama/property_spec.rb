require "spec_helper"

RSpec.describe Roomorama::Property do
  let(:identifier) { "JPN123" }

  subject { described_class.new(identifier) }

  it "sets its own identifier upon initialization" do
    expect(subject.identifier).to eq "JPN123"
  end

  it "is able to set and retrieve property attributes" do
    subject.title = "Beautiful Apartment in Paris"
    subject.cancellation_policy = "elite"

    expect(subject.title).to eq "Beautiful Apartment in Paris"
    expect(subject.cancellation_policy).to eq "elite"
  end

  it "is nil for attributes not set" do
    expect(subject.description).to be_nil
  end

  describe "#multi_unit!" do
    it "converts the property to multi unit" do
      expect(subject).not_to be_multi_unit
      subject.multi_unit!

      expect(subject).to be_multi_unit
    end
  end

  describe "#instant_booking!" do
    it "converts the property to instant booking" do
      expect(subject).not_to be_instant_booking
      subject.instant_booking!

      expect(subject).to be_instant_booking
    end
  end

  describe "#add_image" do
    let(:image) { Roomorama::Image.new("ID123") }

    before do
      image.url = "https://www.example.org/image.png"
    end

    it "adds the given image to the list of property images" do
      expect(subject.add_image(image)).to be
      expect(subject.images).to include image
    end

    it "rejects invalid image objects" do
      image.url = nil

      expect {
        subject.add_image(image)
      }.to raise_error Roomorama::Image::ValidationError
    end
  end

  describe "#add_unit" do
    let(:unit) { Roomorama::Unit.new("UNIT123") }

    before do
      image = Roomorama::Image.new("IMG1")
      image.url = "https://www.example.org/units/image1.png"
      unit.add_image(image)

      unit.update_calendar("2016-05-22" => true)
    end

    it "adds a unit to the list of units of that property" do
      subject.add_unit(unit)
      expect(subject.units).to include unit
    end

    it "marks the property as multi-unit" do
      subject.multi_unit = false
      subject.add_unit(unit)

      expect(subject).to be_multi_unit
    end

    it "validates added units" do
      unit.images.clear
      expect {
        subject.add_unit(unit)
      }.to raise_error Roomorama::Unit::ValidationError
    end
  end

  describe "#update_calendar" do
    it "updates its calendar with the data given" do
      calendar = { "2016-05-22" => true, "2016-05-25" => true }
      expect(subject.update_calendar(calendar)).to be

      expect(subject.calendar).to eq({ "2016-05-22" => true, "2016-05-25" => true })
    end
  end

  describe "#validate!" do
    before do
      # populate some data so that the object is valid
      subject.identifier = "PROP1"

      image = Roomorama::Image.new("IMG1")
      image.url = "https://wwww.example.org/image1.png"
      subject.add_image(image)

      image = Roomorama::Image.new("IMG2")
      image.url = "https://wwww.example.org/image2.png"
      subject.add_image(image)

      subject.update_calendar({
        "2016-05-22" => true,
        "2015-05-28" => true
      })
    end

    it "is invalid if the identifier is not given" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Property::ValidationError
    end

    it "is invalid if there are no images associated with the property" do
      subject.images.clear
      expect {
        subject.validate!
      }.to raise_error Roomorama::Property::ValidationError
    end

    it "is invalid if there are no availabilities for the property" do
      allow(subject).to receive(:calendar) { {} }
      expect {
        subject.validate!
      }.to raise_error Roomorama::Property::ValidationError
    end

    it "is valid if all required parameters are present" do
      expect(subject.validate!).to be
    end
  end
end
