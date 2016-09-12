require "spec_helper"

RSpec.describe Roomorama::Image do
  let(:identifier) { "IMG123" }

  subject { described_class.new(identifier) }

  it "sets its own identifier upon initialization" do
    expect(subject.identifier).to eq "IMG123"
  end

  it "is able to set and retrieve image attributes" do
    subject.caption = "Swimming Pool"
    subject.url     = "https://www.example.org/image.png"

    expect(subject.caption).to eq "Swimming Pool"
    expect(subject.url).to eq "https://www.example.org/image.png"
  end

  it "is nil for attributes not set" do
    expect(subject.caption).to be_nil
  end

  describe ".load" do
    let(:attributes) {
      {
        identifier: "img1",
        url:        "https://www.example.org/img1",
        caption:    "Swimming Pool"
      }
    }

    it "generates a new instance of Image with the given attributes" do
      image = described_class.load(attributes)

      expect(image).to be_a Roomorama::Image
      expect(image.identifier).to eq "img1"
      expect(image.url).to eq "https://www.example.org/img1"
      expect(image.caption).to eq "Swimming Pool"
    end
  end

  describe "#[]=" do
    it "sets the given attribute if it exists" do
      expect(subject.caption).to be_nil
      subject[:caption] = "Swimming Pool"
      expect(subject.caption).to eq "Swimming Pool"
    end

    it "ignores the call if the attribute is unknown" do
      expect {
        subject[:invalid] = "foo"
      }.not_to raise_error
    end
  end

  describe "#validate!" do
    it "ensures there is a valid image identifier" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error(
        Roomorama::Image::ValidationError,
        "Invalid image object: identifier was not given, or is empty"
      )
    end

    it "does not allow empty URLs" do
      subject.url = nil
      expect {
        subject.validate!
      }.to raise_error(
        Roomorama::Image::ValidationError,
        "Invalid image object: URL was not given, or is empty"
      )
    end

    it "does not allow invalid URLs" do
      subject.url = "something://very.invalid"
      expect {
        subject.validate!
      }.to raise_error(
        Roomorama::Image::ValidationError,
        "Invalid image object: URL is invalid"
      )
    end
  end

  describe "#to_h" do
    before do
      subject.url     = "https://www.example.org/imagex.png"
      subject.caption = "Foosball Table"
    end

    it "serializes all attributes" do
      expect(subject.to_h).to eq({
        identifier: "IMG123",
        url:        "https://www.example.org/imagex.png",
        caption:    "Foosball Table"
      })
    end
  end
end
