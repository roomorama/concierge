require "spec_helper"

RSpec.describe Concierge::RoomoramaClient::Property do
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
    let(:image) { Concierge::RoomoramaClient::Image.new("ID123") }

    before do
      image.url = "https://www.example.org/image.png"
    end

    it "adds the given image to the list of property images" do
      expect(subject.add_image(image)).to be
      expect(subject.send(:_images)).to include image
    end

    it "rejects invalid image objects" do
      image.url = nil

      expect {
        subject.add_image(image)
      }.to raise_error Concierge::RoomoramaClient::Image::ValidationError
    end
  end

  describe "#update_calendar" do
    it "updates its calendar with the data given" do
      calendar = { "2016-05-22" => true, "2016-05-25" => true }
      expect(subject.update_calendar(calendar)).to be

      expect(subject.send(:_calendar)).to eq({ "2016-05-22" => true, "2016-05-25" => true })
    end
  end
end
