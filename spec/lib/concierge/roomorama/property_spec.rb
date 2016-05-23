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

  describe "#to_h" do
    before do
      # populate the property with some basic data
      subject.title        = "Studio Apartment in Paris"
      subject.description  = "Bonjour!"
      subject.nightly_rate = 100
      subject.currency     = "EUR"

      image         = Roomorama::Image.new("IMG1")
      image.url     = "https://www.example.org/image1.png"
      image.caption = "Swimming Pool"
      subject.add_image(image)

      image         = Roomorama::Image.new("IMG2")
      image.url     = "https://www.example.org/image2.png"
      image.caption = "Barbecue Pit"
      subject.add_image(image)

      subject.update_calendar({
        "2016-05-22" => true,
        "2016-05-20" => false,
        "2016-05-28" => true,
        "2016-05-21" => true
      })

      unit = Roomorama::Unit.new("UNIT1")
      unit.title = "Unit 1"
      unit.nightly_rate = 200
      unit.floor = 3

      image         = Roomorama::Image.new("UNIT1-IMG1")
      image.url     = "https://www.example.org/unit1/image1.png"
      image.caption = "Bedroom 1"
      unit.add_image(image)

      image         = Roomorama::Image.new("UNIT1-IMG2")
      image.url     = "https://www.example.org/unit1/image2.png"
      image.caption = "Bedroom 2"
      unit.add_image(image)

      unit.update_calendar("2016-05-22" => true, "2016-05-28" => true)

      subject.add_unit(unit)

      unit = Roomorama::Unit.new("UNIT2")
      unit.title = "Unit 2"
      unit.description = "Largest Available Unit"
      unit.number_of_double_beds = 10

      image         = Roomorama::Image.new("UNIT2-IMG1")
      image.url     = "https://www.example.org/unit2/image1.png"
      unit.add_image(image)

      image         = Roomorama::Image.new("UNIT2-IMG2")
      image.url     = "https://www.example.org/unit2/image2.png"
      unit.add_image(image)

      unit.update_calendar("2016-05-22" => true, "2016-05-28" => true)

      subject.add_unit(unit)
    end

    let(:expected_attributes) {
      {
        identifier:      "JPN123",
        title:           "Studio Apartment in Paris",
        description:     "Bonjour!",
        nightly_rate:    100,
        currency:        "EUR",
        multi_unit:      true,
        instant_booking: false,

        images: [
          {
            identifier: "IMG1",
            url:        "https://www.example.org/image1.png",
            caption:    "Swimming Pool"
          },
          {
            identifier: "IMG2",
            url:        "https://www.example.org/image2.png",
            caption:    "Barbecue Pit"
          }
        ],

        availabilities: {
          start_date: "2016-05-20",
          data:       "011111111"
        }
      }
    }

    let(:units_attributes) {
      [
        {
          identifier:   "UNIT1",
          title:        "Unit 1",
          nightly_rate: 200,
          floor:        3,

          images: [
            {
              identifier: "UNIT1-IMG1",
              url:        "https://www.example.org/unit1/image1.png",
              caption:    "Bedroom 1"
            },
            {
              identifier: "UNIT1-IMG2",
              url:        "https://www.example.org/unit1/image2.png",
              caption:    "Bedroom 2"
            }
          ],

          availabilities: {
            start_date: "2016-05-22",
            data:       "1111111"
          }
        },
        {
          identifier:            "UNIT2",
          title:                 "Unit 2",
          description:           "Largest Available Unit",
          number_of_double_beds: 10,

          images: [
            {
              identifier: "UNIT2-IMG1",
              url:        "https://www.example.org/unit2/image1.png"
            },
            {
              identifier: "UNIT2-IMG2",
              url:        "https://www.example.org/unit2/image2.png"
            }
          ],

          availabilities: {
            start_date: "2016-05-22",
            data:       "1111111"
          }
        }
      ]
    }

    it "builds a proper API payload, removing non-defined keys" do
      expect(subject.to_h).to eq(expected_attributes.merge!(units: units_attributes))
    end

    it "does not include units data if the property is not declared to be multi-unit" do
      expected_attributes[:multi_unit] = false
      subject.multi_unit               = false

      expect(subject.to_h).to eq expected_attributes
    end
  end
end
