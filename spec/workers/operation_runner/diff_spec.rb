require "spec_helper"

RSpec.describe Workers::OperationRunner::Diff do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:endpoint) { "https://api.staging.roomorama.com/v1.0/host/apply" }
  let(:host) { create_host }
  let(:roomorama_property) {
    Roomorama::Property.new("prop1").tap do |property|
      property.title        = "Studio Apartment"
      property.description  = "Largest Apartment in New York"
      property.nightly_rate = 100
      property.weekly_rate  =  200
      property.monthly_rate = 300

      image = Roomorama::Image.new("img1")
      image.identifier = "img1"
      image.url        = "https://www.example.org/img1"
      property.add_image(image)

      image = Roomorama::Image.new("img2")
      image.identifier = "img2"
      image.url        = "https://www.example.org/img2"
      image.caption    =  "Swimming Pool"
      property.add_image(image)

      property.update_calendar({
        "2016-05-24" => true,
        "2016-05-23" => true,
        "2016-05-26" => false,
        "2016-05-28" => false,
        "2016-05-21" => true,
        "2016-05-29" => true,
      })
    end
  }

  let(:diff) {
    Roomorama::Diff.new("prop1").tap do |diff|
      diff.title = "New Title for property"
    end
  }

  let(:operation) { Roomorama::Client::Operations.diff(diff) }
  let(:roomorama_client) { Roomorama::Client.new(host.access_token) }

  subject { described_class.new(host, operation, roomorama_client) }

  before do
    # before running the tests, create the corresponding database record since
    # this is an update call.
    property = Property.new(
      identifier: roomorama_property.identifier,
      host_id:    host.id,
      data:       roomorama_property.to_h.tap { |h| h.delete(:availabilities) }
    )

    PropertyRepository.create(property)

    # set back the title to the new one, since the instance received by the
    # +described_class+ represents the new version of the property.
    roomorama_property.title = "New Title for property"
  end

  describe "#perform" do
    it "returns the underlying network problem, if any" do
      stub_call(:put, endpoint) { raise Faraday::TimeoutError }
      result = subject.perform(roomorama_property)

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "saves the context information" do
      stub_call(:put, endpoint) { raise Faraday::TimeoutError }

      expect {
        subject.perform(roomorama_property)
      }.to change { Concierge.context.events.size }

      event = Concierge.context.events.last
      expect(event).to be_a Concierge::Context::NetworkFailure
    end

    it "is unsuccessful if the API call fails" do
      stub_call(:put, endpoint) { [422, {}, read_fixture("roomorama/invalid_type.json")] }
      result = nil

      expect {
        result = subject.perform(roomorama_property)
      }.not_to change { PropertyRepository.count }

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_422
    end

    it "returns the persisted property in a Result if successful" do
      stub_call(:put, endpoint) { [202, {}, [""]] }
      result = subject.perform(roomorama_property)

      expect(result).to be_a Result
      expect(result).to be_success

      property = result.value
      expect(property).to be_a Property
      expect(property.identifier).to eq "prop1"
      expect(property.host_id).to eq host.id
      data = roomorama_property.to_h.tap { |h| h.delete(:availabilities) }
      expect(property.data.to_h.keys).to eq data.keys.map(&:to_s)
      expect(property.data[:title]).to eq "New Title for property"
    end
  end
end
