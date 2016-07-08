require "spec_helper"

RSpec.describe Roomorama::Client do
  include Support::HTTPStubbing

  let(:property)     { Roomorama::Property.new("JPN123") }
  let(:access_token) { "ACCESS_TOKEN" }

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

  subject { described_class.new(access_token) }

  describe "#initialize" do
    it "defaults to the value specified in the environment variable" do
      old_environment = ENV["ROOMORAMA_API_ENVIRONMENT"]
      ENV["ROOMORAMA_API_ENVIRONMENT"] = "production"
      client = nil

      expect {
        client = described_class.new(access_token)
      }.not_to raise_error

      expect(client.api_url).to eq "https://api.roomorama.com"
      ENV["ROOMORAMA_API_ENVIRONMENT"] = old_environment
    end

    it "allows a different environment to be specified" do
      client = nil

      expect {
        client = described_class.new(access_token, environment: :sandbox)
      }.not_to raise_error

      expect(client.api_url).to eq "https://api.sandbox.roomorama.com"
    end

    it "raises an error in case an invalid environment is passed" do
      expect {
        described_class.new(access_token, environment: :invalid)
      }.to raise_error Roomorama::Client::UnknownEnvironmentError
    end
  end

  describe "#perform" do
    let(:operation) { Roomorama::Client::Operations::Publish.new(property) }
    let(:url) { "https://api.roomorama.com/v1.0/host/publish" }

    it "recovers from network failures" do
      stub_call(:post, url) { raise Faraday::TimeoutError }
      result = subject.perform(operation)

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "sends the request with the correct parameters" do
      serialized_property = {
        identifier:      "JPN123",
        title:           "Studio Apartment in Paris",
        description:     "Bonjour!",
        multi_unit:      false,
        currency:        "EUR",
        nightly_rate:    100,
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

      headers = {
        "Authorization" => "Bearer ACCESS_TOKEN",
        "Content-Type"  => "application/json"
      }

      expect_any_instance_of(Concierge::HTTPClient).to receive(:post).with(
        "/v1.0/host/publish",
        serialized_property.to_json,
        headers
      ).once

      subject.perform(operation)
    end

    it "returns the result of the network call when successful" do
      stub_call(:post, url) { [200, {}, ""] }
      result = subject.perform(operation)

      expect(result).to be_a Result
      expect(result).to be_success
    end
  end
end
