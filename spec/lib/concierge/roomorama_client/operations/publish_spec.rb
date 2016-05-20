require "spec_helper"

RSpec.describe Concierge::RoomoramaClient::Operations::Publish do
  let(:property) { Concierge::RoomoramaClient::Property.new("JPN123") }

  subject { described_class.new(property) }

  before do
    # populate the property with some basic data
    property.title        = "Studio Apartment in Paris"
    property.description  = "Bonjour!"
    property.nightly_rate = 100
    property.currency     = "EUR"

    image         = Concierge::RoomoramaClient::Image.new("IMG1")
    image.url     = "https://www.example.org/image1.png"
    image.caption = "Swimming Pool"
    property.add_image(image)

    image         = Concierge::RoomoramaClient::Image.new("IMG2")
    image.url     = "https://www.example.org/image2.png"
    image.caption = "Barbecue Pit"
    property.add_image(image)

    property.update_calendar({
      "2016-05-22" => true,
      "2016-05-20" => false,
      "2016-05-28" => true,
      "2016-05-21" => true
    })

    unit = Concierge::RoomoramaClient::Unit.new("UNIT1")
    unit.title = "Unit 1"
    unit.nightly_rate = 200
    unit.floor = 3

    image         = Concierge::RoomoramaClient::Image.new("UNIT1-IMG1")
    image.url     = "https://www.example.org/unit1/image1.png"
    image.caption = "Bedroom 1"
    unit.add_image(image)

    image         = Concierge::RoomoramaClient::Image.new("UNIT1-IMG2")
    image.url     = "https://www.example.org/unit1/image2.png"
    image.caption = "Bedroom 2"
    unit.add_image(image)

    unit.update_calendar("2016-05-22" => true, "2016-05-28" => true)

    property.add_unit(unit)

    unit = Concierge::RoomoramaClient::Unit.new("UNIT2")
    unit.title = "Unit 2"
    unit.description = "Largest Available Unit"
    unit.number_of_double_beds = 10

    image         = Concierge::RoomoramaClient::Image.new("UNIT2-IMG1")
    image.url     = "https://www.example.org/unit2/image1.png"
    unit.add_image(image)

    image         = Concierge::RoomoramaClient::Image.new("UNIT2-IMG2")
    image.url     = "https://www.example.org/unit2/image2.png"
    unit.add_image(image)

    unit.update_calendar("2016-05-22" => true, "2016-05-28" => true)

    property.add_unit(unit)
  end

  describe "#initialize" do
    it "allows object creation for valid properties" do
      expect(subject).to be
    end

    it "raises an error in case an invalid property is passed" do
      property.images.clear
      expect {
        subject
      }.to raise_error Concierge::RoomoramaClient::Property::ValidationError
    end
  end

  describe "#endpoint" do
    it "knows the endpoint where a property can be published" do
      expect(subject.endpoint).to eq "/v1.0/host/publish"
    end
  end

  describe "#method" do
    it "knows the request methdo to be used when publishing" do
      expect(subject.request_method).to eq :post
    end
  end

  describe "#request_data" do
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
      expect(subject.request_data).to eq(expected_attributes.merge!(units: units_attributes))
    end

    it "does not include units data if the property is not declared to be multi-unit" do
      expected_attributes[:multi_unit] = false
      property.multi_unit              = false

      expect(subject.request_data).to eq expected_attributes
    end
  end
end
