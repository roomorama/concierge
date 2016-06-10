require "spec_helper"

RSpec.describe Roomorama::Client::Operations::Publish do
  let(:property) { Roomorama::Property.new("JPN123") }

  subject { described_class.new(property) }

  before do
    # populate the property with some basic data
    property.title        = "Studio Apartment in Paris"
    property.description  = "Bonjour!"
    property.nightly_rate = 100
    property.currency     = "EUR"

    image         = Roomorama::Image.new("IMG1")
    image.url     = "https://www.example.org/image1.png"
    image.caption = "Swimming Pool"
    property.add_image(image)

    image         = Roomorama::Image.new("IMG2")
    image.url     = "https://www.example.org/image2.png"
    image.caption = "Barbecue Pit"
    property.add_image(image)

    property.update_calendar({
      "2016-05-22" => true,
      "2016-05-20" => false,
      "2016-05-28" => true,
      "2016-05-21" => true
    })
  end

  describe "#initialize" do
    it "allows object creation for valid properties" do
      expect(subject).to be
    end

    it "raises an error in case an invalid property is passed" do
      property.images.clear
      expect {
        subject
      }.to raise_error Roomorama::Property::ValidationError
    end
  end

  describe "#endpoint" do
    it "knows the endpoint where a property can be published" do
      expect(subject.endpoint).to eq "/v1.0/host/publish"
    end
  end

  describe "#method" do
    it "knows the request method to be used when publishing" do
      expect(subject.request_method).to eq :post
    end
  end

  describe "#request_data" do
    it "calls the +to_h+ method of the underlying property" do
      expect(property).to receive(:to_h)
      subject.request_data
    end
  end
end
