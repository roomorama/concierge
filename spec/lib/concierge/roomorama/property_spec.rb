require "spec_helper"
require_relative "translated"

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

  describe ".load" do
    let(:attributes) {
      {
        identifier:           "prop1",
        title:                "Studio Apartment in Chicago",
        max_guests:           2,
        nightly_rate:         100,
        pets_allowed:         false,
        default_to_available: false,
        type:                 "bnb",

        images: [
          {
            identifier: "img1",
            url:        "https://www.example.org/img1",
            caption:    "Barbecue Pit"
          }
        ],

        units: [
          {
            identifier:      "unit1",
            title:           "Unit 1",
            number_of_units: 2,

            images: [
              {
                identifier: "unit1img1",
                url:        "https://www.example.org/unit1img1",
              },
              {
                identifier: "unit1img2",
                url:        "https://www.example.org/unit1img2",
              }
            ]
          },
          {
            identifier:      "unit2",
            title:           "Unit 2",

            images: [
              {
                identifier: "unit2img1",
                url:        "https://www.example.org/unit2img1",
              }
            ]
          }
        ]
      }
    }

    it "creates a new property with associated images and units" do
      result = described_class.load(attributes)
      expect(result).to be_a Result
      expect(result).to be_success

      property = result.value
      expect(property).to be_a Roomorama::Property

      expect(property.title).to eq "Studio Apartment in Chicago"
      expect(property.max_guests).to eq 2
      expect(property.nightly_rate).to eq 100
      expect(property.pets_allowed).to eq false
      expect(property.default_to_available).to eq false
      expect(property).to be_multi_unit

      images = property.images
      expect(images.size).to eq 1

      image = images.first
      expect(image.identifier).to eq "img1"
      expect(image.url).to eq "https://www.example.org/img1"
      expect(image.caption).to eq "Barbecue Pit"

      units = property.units
      expect(units.size).to eq 2

      unit = units.first
      expect(unit.identifier).to eq "unit1"
      expect(unit.title).to eq "Unit 1"
      expect(unit.number_of_units).to eq 2

      images = unit.images
      expect(images.size).to eq 2

      image = images.first
      expect(image.identifier).to eq "unit1img1"
      expect(image.url).to eq "https://www.example.org/unit1img1"

      image = images.last
      expect(image.identifier).to eq "unit1img2"
      expect(image.url).to eq "https://www.example.org/unit1img2"

      unit = units.last
      expect(unit.identifier).to eq "unit2"
      expect(unit.title).to eq "Unit 2"

      images = unit.images
      expect(images.size).to eq 1

      image = images.first
      expect(image.identifier).to eq "unit2img1"
      expect(image.url).to eq "https://www.example.org/unit2img1"

      expect(property.to_h).to eq attributes.merge(instant_booking: false, multi_unit: true)
    end

    it "returns an unsuccessful result in case there is missing data"  do
      attributes[:images].first.delete(:identifier)
      result = described_class.load(attributes)

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :missing_required_data
      expect(result.error.data).to eq({
        error:      "Invalid image object: identifier was not given, or is empty",
        attributes: attributes
      })
    end
  end

  describe "#[]=" do
    it "sets attributes to the given value" do
      expect(subject.title).to be_nil
      subject[:title] = "Apartment in Las Vegas"
      expect(subject.title).to eq "Apartment in Las Vegas"
    end

    it "ignores the method call in case the attribute is unknown" do
      expect {
        subject[:unknown] = "attribute"
      }.not_to raise_error
    end
  end

  it_behaves_like "translated object"

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
  end

  describe "#add_unit" do
    let(:unit) { Roomorama::Unit.new("UNIT123") }

    before do
      image = Roomorama::Image.new("IMG1")
      image.url = "https://www.example.org/units/image1.png"
      unit.add_image(image)
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

      unit = Roomorama::Unit.new("UNIT1")
      unit.title = "Largest Unit"
      image = Roomorama::Image.new("UNIT1_IMG2")
      image.url = "https://wwww.example.org/unit1/image2.png"
      unit.add_image(image)

      subject.add_unit(unit)

      subject.type = "bnb"
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

    it "rejects invalid image objects" do
      subject.images.first.url = nil

      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end

    it "validates units" do
      subject.units.first.identifier = nil

      expect {
        subject.validate!
      }.to raise_error Roomorama::Unit::ValidationError
    end

    it "is valid if all required parameters are present" do
      expect(subject.validate!).to be
    end

    it "is valid if it has id and is disabled" do
      subject.images.clear
      subject.units.clear
      subject.disabled = true
      expect(subject.validate!).to be true
    end
  end

  describe "#to_h" do
    before do
      # populate the property with some basic data
      subject.title          = "Studio Apartment in Paris"
      subject.es.title       = "Baguette"
      subject.description    = "Bonjour!"
      subject.es.description = "Pate and Baguette"
      subject.nightly_rate   = 100
      subject.currency       = "EUR"
      subject.owner_city     = "Seoul"

      image         = Roomorama::Image.new("IMG1")
      image.url     = "https://www.example.org/image1.png"
      image.caption = "Swimming Pool"
      subject.add_image(image)

      image         = Roomorama::Image.new("IMG2")
      image.url     = "https://www.example.org/image2.png"
      image.caption = "Barbecue Pit"
      subject.add_image(image)

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
        owner_city:      "Seoul",
        instant_booking: false,

        translations: {
          es: {
            title:       "Baguette",
            description: "Pate and Baguette"
          }
        },

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
        ]
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
          ]
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
          ]
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
