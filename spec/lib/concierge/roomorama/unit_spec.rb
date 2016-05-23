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

    it "is invalid if there are no availabilities for the unit" do
      allow(subject).to receive(:calendar) { {} }
      expect {
        subject.validate!
      }.to raise_error Roomorama::Unit::ValidationError
    end

    it "is valid if all required parameters are present" do
      expect(subject.validate!).to be
    end
  end
end
