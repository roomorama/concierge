require "spec_helper"

RSpec.describe Roomorama::Unit do
  let(:identifier) { "JPN123UN" }

  subject { described_class.new(identifier) }

  it "sets its own identifier upon initialization" do
    expect(subject.identifier).to eq "JPN123UN"
  end

  it "is able to set and retrieve property attributes" do
    subject.title = "Beautiful Apartment in Paris"
    subject.number_of_units = 30

    expect(subject.title).to eq "Beautiful Apartment in Paris"
    expect(subject.number_of_units).to eq 30
  end

  it "is nil for attributes not set" do
    expect(subject.description).to be_nil
  end

  describe ".load" do
    let(:attributes) {
      {
        title:        "Studio Apartment in Rio",
        nightly_rate: 100,
        minimum_stay: 2,
      }

      it "creates a new instance setting the passed attributes" do
        unit = described_class.load(attributes)

        expect(unit).to be_a Roomorama::Unit
        expect(unit.title).to eq "Studio Apartment"
        expect(unit.nightly_rate).to eq 100
        expect(unit.minimum_stay).to eq 2
      end

      it "is able to create associated images" do
        attributes[:images] = [
          {
            identifier: "img1",
            url:        "https://www.example.org/img1",
            caption:    "Swimming Pool"
          },
          {
            identifier: "img2",
            url:        "https://www.example.org/img1"
          }
        ]

        unit = described_class.load(attributes)
        expect(unit).to be_a Roomorama::Unit

        images = unit.images
        expect(images).to be_a Array
        expect(images.size).to eq 2

        image = images.first
        expect(image.identifier).to eq "img1"
        expect(image.identifier).to eq "https://www.example.org/img1"
        expect(image.identifier).to eq "Swimming Pool"

        image = images.last
        expect(image.identifier).to eq "img2"
        expect(image.identifier).to eq "https://www.example.org/img2"
      end
    }
  end

  describe "#[]=" do
    it "allows setting specific parameters" do
      expect(subject.title).to be_nil

      subject[:title] = "Studio Apartment"
      expect(subject.title).to eq "Studio Apartment"
    end

    it "ignores unknown parameters" do
      expect {
        subject[:unknown] = "attribute"
      }.not_to raise_error
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

  describe "#update_calendar" do
    it "updates its calendar with the data given" do
      calendar = { "2016-05-22" => true, "2016-05-25" => true }
      expect(subject.update_calendar(calendar)).to be

      expect(subject.calendar).to eq({ "2016-05-22" => true, "2016-05-25" => true })
    end
  end

  describe "#validate!" do
    before do
      subject.identifier = "UNIT1"

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

    it "is invalid if the identifier is not present" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Unit::ValidationError
    end

    it "is invalid if there are no images associated with the unit" do
      allow(subject).to receive(:images) { [] }
      expect {
        subject.validate!
      }.to raise_error Roomorama::Unit::ValidationError
    end

    it "rejects invalid image objects" do
      subject.images.first.url = nil

      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end

    it "is valid if all required parameters are present" do
      expect(subject.validate!).to be
    end

    it "valid if there are no availabilities for the unit" do
      allow(subject).to receive(:calendar) { {} }
      expect(subject.validate!).to be
    end
  end

  describe "#require_calendar!" do
    before do
      subject.update_calendar({
        "2016-05-22" => true,
        "2015-05-28" => true
      })
    end

    it "is valid in case there is a non-empty availabilities calendar" do
      expect(subject.require_calendar!).to be
    end

    it "is invalid in case the availabilities calendar is empty" do
      allow(subject).to receive(:calendar) { {} }
      expect {
        subject.require_calendar!
      }.to raise_error  Roomorama::Unit::ValidationError
    end
  end

  describe "#to_h" do
    before do
      subject.title        = "Nice Unit"
      subject.description  = "Largest Unit Available"
      subject.nightly_rate = 100
      subject.weekly_rate  = 200
      subject.monthly_rate = 300

      image = Roomorama::Image.new("image1")
      image.url = "https://www.example.org/image1.png"
      subject.add_image(image)

      image = Roomorama::Image.new("image2")
      image.url = "https://www.example.org/image2.png"
      subject.add_image(image)

      subject.update_calendar({
        "2016-06-20" => true,
        "2016-06-22" => true,
        "2016-06-25" => true,
        "2016-06-28" => false,
        "2016-06-21" => true,
      })
    end

    it "serializes all attributes" do
      expect(subject.to_h).to eq({
        identifier:   "JPN123UN",
        title:        "Nice Unit",
        description:  "Largest Unit Available",
        nightly_rate: 100,
        weekly_rate:  200,
        monthly_rate: 300,

        images: [
          {
            identifier: "image1",
            url:        "https://www.example.org/image1.png"
          },
          {
            identifier: "image2",
            url:        "https://www.example.org/image2.png"
          }
        ],

        availabilities: {
          start_date: "2016-06-20",
          data:        "111111110"
        }
      })
    end
  end
end
