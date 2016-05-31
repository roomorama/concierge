require "spec_helper"

RSpec.describe Workers::Router do
  include Support::Factories

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

  subject { described_class.new(host) }

  describe "#dispatch" do
    it "enqueues a publish operation in case the property was not previously imported" do
      operation = subject.dispatch(roomorama_property)

      expect(operation).to be_a Roomorama::Client::Operations::Publish
      expect(operation.property).to eq roomorama_property
    end

    it "enqueues a publish operation if a property from another host with the same identifier exists" do
      create_property(host_id: host.id + 1, identifier: roomorama_property.identifier)
      operation = subject.dispatch(roomorama_property)

      expect(operation).to be_a Roomorama::Client::Operations::Publish
      expect(operation.property).to eq roomorama_property
    end

    it "enqueues a diff operation if there is a property with the same identifier for the same host" do
      data = Roomorama::Client::Operations.publish(roomorama_property).request_data.merge!(title: "Different title")
      create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)
      operation = subject.dispatch(roomorama_property)

      expect(operation).to be_a Roomorama::Client::Operations::Diff
    end

    it "does not enqueue any operation if there is no difference between the existing property and the new one" do
      data = Roomorama::Client::Operations.publish(roomorama_property).request_data
      create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)

      operation = subject.dispatch(roomorama_property)
      expect(operation).to be_nil
    end
  end
end
