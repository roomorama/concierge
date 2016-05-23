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

  describe "#validate!" do
    it "ensures there is a valid image identifier" do
      subject.identifier = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end

    it "does not allow empty URLs" do
      subject.url = nil
      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end

    it "does not allow invalid URLs" do
      subject.url = "something://very.invalid"
      expect {
        subject.validate!
      }.to raise_error Roomorama::Image::ValidationError
    end
  end
end
