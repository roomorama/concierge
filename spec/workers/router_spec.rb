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

    end
  }

  subject { described_class.new(host) }

  describe "#dispatch" do
    let(:operations) { subject.dispatch(roomorama_property) }

    context "when the property was not previously imported" do
      it "include publish the returned operations" do
        expect(operations.first).to be_a Roomorama::Client::Operations::Publish
        expect(operations.first.property).to eq roomorama_property
      end
    end

    context "when a property from another host with the same identifier exists" do
      it "include publish the returned operations" do
        create_property(host_id: host.id + 1, identifier: roomorama_property.identifier)

        expect(operations.first).to be_a Roomorama::Client::Operations::Publish
        expect(operations.first.property).to eq roomorama_property
      end
    end

    context "when a property from the same host with the same identifier exists" do
      it "include diff in the returned operations" do
        data = roomorama_property.to_h.merge!(title: "Different title")
        create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)

        expect(operations.first).to be_a Roomorama::Client::Operations::Diff
      end
    end

    context "when the property has calendar" do
      before do
        roomorama_property.update_calendar({
          "2016-05-24" => true,
          "2016-05-23" => true,
          "2016-05-26" => false,
          "2016-05-28" => false,
          "2016-05-21" => true,
          "2016-05-29" => true,
        })
      end
      it "include update_calendar in the returned operations" do
        expect(operations.last).to be_a Roomorama::Client::Operations::CalendarUpdate
      end
    end

    it "raises an error if the database contains unrecognisable data" do
      data = roomorama_property.to_h.tap do |attributes|
        attributes[:images].first.merge!(identifier: nil)
      end

      create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)

      expect {
        subject.dispatch(roomorama_property)
      }.to raise_error Workers::Router::InvalidSerializedDataError
    end

    it "does not enqueue any operation if there is no difference between the existing property and the new one" do
      data = Roomorama::Client::Operations.publish(roomorama_property).request_data
      create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)

      expect(operations).to be_empty
    end
  end
end
