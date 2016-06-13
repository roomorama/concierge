require "spec_helper"

RSpec.describe Roomorama::Diff do
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

  describe "#[]=" do
    it "allows setting attributes to the diff" do
      expect(subject.title).to be_nil
      subject[:title] = "New Title"
      expect(subject.title).to eq "New Title"
    end

    it "ignores unknown attributes" do
      expect {
        subject[:unknown] = "attribute"
      }.not_to raise_error
    end
  end

  describe "#erase" do
    it "causes the attribute to be serialized even if blank" do
      subject.title = "New Title"
      subject.erase(:tax_rate)

      expect(subject.to_h).to eq({
        identifier: "JPN123",
        title:      "New Title",
        tax_rate:   nil
      })
    end
  end

  describe "#add_image" do
    let(:image) { Roomorama::Image.new("ID123") }

    before do
      image.url = "https://www.example.org/image.png"
    end

    it "adds the given image to the list of property images" do
      expect(subject.add_image(image)).to be
      expect(subject.image_changes.created).to include image
    end
  end

  describe "#change_image" do
    let(:image_diff) { Roomorama::Diff::Image.new("IMGDIFF123") }

    before do
      image_diff.caption = "Amended caption"
    end

    it "adds the image diff to the list of image changes" do
      expect(subject.change_image(image_diff)).to be
      expect(subject.image_changes.updated).to eq [image_diff]
    end
  end

  describe "#delete_image" do
    it "adds the identifier to the list of images to be deleted" do
      subject.delete_image("IMG_DEL")
      expect(subject.image_changes.deleted).to eq ["IMG_DEL"]
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
      expect(subject.unit_changes.created).to include unit
    end

    it "marks the property as multi-unit" do
      subject.multi_unit = false
      subject.add_unit(unit)

      expect(subject.multi_unit).to eq true
    end
  end

  describe "#change_unit" do
    let(:unit_diff) { Roomorama::Diff::Unit.new("UNIT_DIFF") }

    before do
      unit_diff.title = "New Title"
    end

    it "adds the changed unit to the list of units to be changed" do
      subject.change_unit(unit_diff)
      expect(subject.unit_changes.updated).to eq [unit_diff]
    end
  end

  describe "#delete_unit" do
    it "adds the identifier given to the list of units to be deleted" do
      subject.delete_unit("UNIT_DEL")
      expect(subject.unit_changes.deleted).to eq ["UNIT_DEL"]
    end
  end

  describe "#update_calendar" do
    it "updates its calendar with the data given" do
      calendar = { "2016-05-22" => true, "2016-05-25" => true }
      expect(subject.update_calendar(calendar)).to be

      expect(subject.calendar).to eq({ "2016-05-22" => true, "2016-05-25" => true })
    end
  end

  describe "#empty?" do
    it "is empty if no changes to meta attributes were applied" do
      expect(subject).to be_empty
    end

    it "is not empty if one attribute is changed" do
      subject.title = "New Title"
      expect(subject).not_to be_empty
    end

    it "is not empty if images were added" do
      image = Roomorama::Image.new("img")
      image.url = "https://www.example.org/img.png"
      subject.add_image(image)

      expect(subject).not_to be_empty
    end
  end

  describe "#validate!" do
    it "is invalid if the identifier is not given" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::ValidationError
    end

    it "rejects invalid image objects" do
      image = Roomorama::Image.new("IMG1")
      subject.add_image(image)

      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end

    it "rejects invalid image diff objects" do
      image_diff = Roomorama::Diff::Image.new("IMG1")
      image_diff.caption = nil
      subject.change_image(image_diff)

      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::Image::ValidationError
    end

    it "validates added units" do
      unit = Roomorama::Unit.new("UNIT1")
      unit.images.clear
      subject.add_unit(unit)

      expect {
        subject.validate!
      }.to raise_error Roomorama::Unit::ValidationError
    end

    it "rejects invalid unit diff objects" do
      unit_diff = Roomorama::Diff::Unit.new("UNIT1")
      unit_diff.identifier = nil
      subject.change_unit(unit_diff)

      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::Unit::ValidationError
    end

    it "is if there is non-empty identifier" do
      expect(subject.validate!).to be
    end
  end

  describe "#to_h" do
    before do
      # makes some changes to the property
      subject.title        = "Studio Apartment in Paris"
      subject.description  = "Bonjour!"
      subject.nightly_rate = 100

      image         = Roomorama::Image.new("IMG1")
      image.url     = "https://www.example.org/image1.png"
      image.caption = "Swimming Pool"
      subject.add_image(image)

      image_diff         = Roomorama::Diff::Image.new("IMG2")
      image_diff.caption = "Barbecue Pit (renovated)"
      subject.change_image(image_diff)

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

      unit = Roomorama::Diff::Unit.new("UNIT2")
      unit.title = "New Unit Title"
      unit.number_of_double_beds = 10

      image         = Roomorama::Image.new("UNIT2-IMG1")
      image.url     = "https://www.example.org/unit2/image1.png"
      unit.add_image(image)

      image_diff         = Roomorama::Diff::Image.new("UNIT2-IMG2")
      image_diff.caption = "Improved Living Room"
      unit.change_image(image_diff)

      unit.update_calendar("2016-05-22" => true, "2016-05-28" => true)

      subject.change_unit(unit)
    end

    let(:expected_attributes) {
      {
        identifier:      "JPN123",
        title:           "Studio Apartment in Paris",
        description:     "Bonjour!",
        nightly_rate:    100,
        multi_unit:      true,

        images: {
          create: [
            {
              identifier: "IMG1",
              url:        "https://www.example.org/image1.png",
              caption:    "Swimming Pool"
            }
          ],
          update: [
            {
              identifier: "IMG2",
              caption:    "Barbecue Pit (renovated)"
            }
          ]
        },

        availabilities: {
          start_date: "2016-05-20",
          data:       "011111111"
        },

        units: {
          create: [
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
            }
          ],
          update: [
            {
              identifier:            "UNIT2",
              title:                 "New Unit Title",
              number_of_double_beds: 10,

              images: {
                create: [
                  {
                    identifier: "UNIT2-IMG1",
                    url:        "https://www.example.org/unit2/image1.png"
                  }
                ],
                update: [
                  {
                    identifier: "UNIT2-IMG2",
                    caption:    "Improved Living Room"
                  }
                ]
              },

              availabilities: {
                start_date: "2016-05-22",
                data:       "1111111"
              }
            }
          ]
        }
      }
    }

    it "builds a proper API payload, removing non-defined keys" do
      expect(subject.to_h).to eq(expected_attributes)
    end
  end
end
