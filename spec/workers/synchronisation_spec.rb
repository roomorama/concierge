require "spec_helper"

RSpec.describe Workers::Synchronisation do
  let(:host) {
    host = Host.new(
      supplier_id:  1,
      identifier:   "supplier1",
      username:     "supplier",
      access_token: "abc123"
    )

    HostRepository.create(host)
  }

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

  subject { described_class.new(host) }

  describe "#push" do
    it "includes the property in the list of processed properties" do
      subject.push(roomorama_property)
      expect(subject.processed).to eq %w(prop1)
    end

    it "enqueues a publish operation" do
      expect(subject).to receive(:enqueue)
      operation = subject.push(roomorama_property)

      expect(operation).to be_a Roomorama::Client::Operations::Publish
      expect(operation.property).to eq roomorama_property
    end
  end

  describe "#finish!" do
    it "does nothing if all known properties were processed" do
      subject.push(roomorama_property)
      expect(subject).not_to receive(:enqueue)

      subject.finish!
    end

    it "enqueues a disable operation with non-processed identifiers" do
      create_property(identifier: "prop1", data: { identifier: "prop1" })
      create_property(identifier: "prop2", host_id: host.id + 1)
      create_property(identifier: "prop3", host_id: host.id)

      operations = []
      expect(subject).to receive(:enqueue) { |arg| operations << arg }.twice

      subject.push(roomorama_property)
      subject.finish!

      expect(operations.size).to eq 2

      operation = operations.first
      expect(operation).to be_a Roomorama::Client::Operations::Diff
      expect(operation.property_diff.identifier).to eq "prop1"

      operation = operations.last
      expect(operation).to be_a Roomorama::Client::Operations::Disable
      expect(operation.identifiers).to eq ["prop3"]
    end

    def create_property(overrides = {})
      attributes = {
        identifier: "prop1",
        host_id: host.id,
        data: { title: "Test property" }
      }.merge(overrides)

      property = Property.new(attributes)
      PropertyRepository.create(property)
    end
  end
end
