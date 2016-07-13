require "spec_helper"

RSpec.describe Roomorama::Diff::Unit do
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

  describe "#[]=" do
    it "allows setting unit attributes to the diff" do
      expect(subject.title).to be_nil
      subject[:title] = "New Title"
      expect(subject.title).to eq "New Title"
    end

    it "ignores unknow attributes" do
      expect {
        subject[:unknown] = "attribute"
      }.not_to raise_error
    end
  end

  describe "#erase" do
    it "causes the attribute to be serialized even if blank" do
      subject.title = "New Title"
      subject.erase(:floor)

      expect(subject.to_h).to eq({
        identifier: "JPN123UN",
        title:      "New Title",
        floor:      nil
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

  describe "#validate!" do
    before do
      subject.identifier = "UNIT1"
    end

    it "is invalid if the identifier is not present" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Diff::Unit::ValidationError
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

    it "is valid if all required parameters are present" do
      expect(subject.validate!).to be
    end
  end

  describe "#to_h" do
    before do
      subject.title        = "New Title"
      subject.monthly_rate = 300

      image = Roomorama::Image.new("image1")
      image.url = "https://www.example.org/image1.png"
      subject.add_image(image)

      image_diff = Roomorama::Diff::Image.new("image2")
      image_diff.caption = "New caption"
      subject.change_image(image_diff)

      subject.delete_image("IMGDEL")
    end

    it "changed attributes" do
      expect(subject.to_h).to eq({
        identifier:   "JPN123UN",
        title:        "New Title",
        monthly_rate: 300,

        images: {
          create: [
            {
              identifier: "image1",
              url:        "https://www.example.org/image1.png"
            }
          ],
          update: [
            {
              identifier: "image2",
              caption:    "New caption"
            }
          ],
          delete: ["IMGDEL"]
        }
      })
    end

    it "does not included a type of image change if empty" do
      subject.image_changes.created = []
      expect(subject.to_h[:images]).not_to have_key :create
    end

    it "does not include the `images` field if there are no image changes" do
      subject.image_changes.created = []
      subject.image_changes.updated = []
      subject.image_changes.deleted = []

      expect(subject.to_h).not_to have_key :images
    end
  end
end
