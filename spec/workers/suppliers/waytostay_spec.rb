require "spec_helper"

RSpec.describe Workers::Suppliers::Waytostay do
  include Support::Factories
  include Support::Fixtures

  let(:host) { create_host }
  let(:changes) { {
    properties:   ["001", "002"],
    media:        ["003", "004"],
    availability: ["005", "001"], # 001 is updated in both categories, but should only be dispatched once.
    # rates:        [], #["006"],
    # reviews:        [], #["006"],
    # bookings:     []
  }}
  before do
    allow(subject.client).to receive(:get_changes_since).and_return(changes)

    # properties 001 and 002 is stubbed for client fetches,
    # 003, 004 and 005 stubbed for concierge database
    allow(subject.client).to receive(:get_property) do |ref|
      expect(["001", "002"]).to include ref
      Roomorama::Property.load(
        Concierge::SafeAccessHash.new(
          JSON.parse(read_fixture("waytostay/properties/#{ref}.roomorama-attributes.json"))
        )
      )
    end
    create_property(identifier: "003", host_id: host.id)
    create_property(identifier: "004", host_id: host.id)
    create_property(identifier: "005", host_id: host.id)
    create_property(identifier: "006", host_id: host.id)

    allow(subject.client).to receive(:update_media) do |property|
      property.drop_images!
      new_image = Roomorama::Image.new("#{property.identifier}_image")
      new_image.url = "http://www.example.org/image/#{property.identifier}"
      property.add_image new_image
      Result.new(property)
    end

    allow(subject.client).to receive(:update_availabilities) do |property|
      Result.new(property)
    end
  end

  subject { described_class.new(host) }

  describe "perform" do
    it "should start property attributes synchronisation" do
      properties_to_update_count = 5 # 001 to 005. changes in 006 rates is not dispatched
      expect(subject.synchronisation.router).to receive(:dispatch)
        .exactly(properties_to_update_count).times
      subject.perform
    end
  end
end

