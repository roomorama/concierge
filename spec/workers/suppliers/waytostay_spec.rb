require "spec_helper"

RSpec.describe Workers::Suppliers::Waytostay do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  subject { described_class.new(host) }

  let(:host) { create_host }

  before do

    allow(subject.client).to receive(:update_media) do |property|
      property.drop_images!
      new_image = Roomorama::Image.new("#{property.identifier}_image")
      new_image.url = "http://www.example.org/image/#{property.identifier}"
      property.add_image new_image
      Result.new(property)
    end

    allow(subject.client).to receive(:get_availabilities) do |property, nightly_rate|
      Result.new([Roomorama::Calendar::Entry.new(date: Date.today, available:true, nightly_rate:nightly_rate)])
    end
  end

  context "synchronizing properties" do
    let(:changes) { {
      properties:   ["001", "002"],
      media:        ["003", "004"],
      availability: ["005", "001"], # 001 is updated in both categories, but should only be dispatched once.
      # rates:        [], #["006"],
      # reviews:        [], #["006"],
      # bookings:     []
    }}
    before do
      allow(subject).to receive(:last_synced_timestamp) { Time.now() }
      allow(subject.client).to receive(:get_changes_since).and_return(Result.new(changes))

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

    end

    describe "perform" do
      before do
        stub_call(:put, "https://api.roomorama.com/v1.0/host/update_calendar") {
          [202, {}, [""]]
        }
      end

      context "when successful" do
        it "should start property attributes synchronisation" do
          properties_to_update_count = 5 # 001 to 005. changes in 006 rates is not dispatched
          expect(subject.property_sync.router).to receive(:dispatch)
            .exactly(properties_to_update_count).times
          subject.perform
        end
      end

      context "when there's error getting waytostay changes" do
        before do
          allow(subject.client).to receive(:get_changes_since) do
            subject.client.send(:augment_missing_fields, ["expected_key"])
            Result.error(:unrecognised_response)
          end
        end
        it "should create external errors" do
          expect {
            subject.perform
          }.to change { ExternalErrorRepository.count }.by 1
          error = ExternalErrorRepository.last
          expect(error.code).to eq "unrecognised_response"
          expect(error.context[:events].last["label"]).to eq "Response Mismatch"
        end
      end
    end
  end
end
