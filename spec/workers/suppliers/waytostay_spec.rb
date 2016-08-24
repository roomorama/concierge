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

    allow(subject.client).to receive(:get_availabilities) do |property|
      Result.new([Roomorama::Calendar::Entry.new(date: Date.today, available:true, nightly_rate:100)])
    end
  end

  describe "#last_synced_timestamp" do
    context "there are no successful syncs" do
      it { expect(subject.send(:last_synced_timestamp)).to be_nil }
    end

    context "there are successful syncs" do
      before do
        create_sync_process(successful: true, host_id: host.id)
      end

      it { expect(subject.send(:last_synced_timestamp)).to be_a Integer }
    end
  end

  context 'there are events from previous syncs in current context' do
    let(:fresh_subject) { described_class.new(host) }
    before do
      Concierge.context = Concierge::Context.new(type: "batch")
      sync_process = Concierge::Context::SyncProcess.new(
        worker:     "metadata",
        host_id:    "UNRELATED_HOST",
        identifier: "UNRELATED_PROPERTY"
      )
      # must be augmented before described_class is initialized
      Concierge.context.augment(sync_process)
      allow(fresh_subject.client).to receive(:get_changes_since) do
        fresh_subject.client.send(:augment_missing_fields, ["expected_key"])
        Result.error(:unrecognised_response)
      end
    end
    it 'announces an error without any unrelated context' do
      fresh_subject.perform
      error = ExternalErrorRepository.last
      expect(error.context.get("events").to_s).to_not include("UNRELATED_PROPERTY")
    end
  end

  describe "#load_existing" do
    context "ref is not found in database" do
      it "should fetch from api if ref is not found in database" do
        expect(subject.client).to receive(:get_property).once { Result.new }
        expect(subject.client).to receive(:update_media).once {}
        subject.send(:load_existing, "non_existing_ref")
      end
    end
  end

  context "synchronizing properties" do
    let(:changes) { {
      properties:   ["001", "002"],
      media:        ["003", "004"],
      availability: ["005", "001"] # 001 is updated in both categories, but should only be dispatched once.
    }}

    before do
      allow(subject).to receive(:last_synced_timestamp) { Time.now().to_i }
      allow(subject.client).to receive(:get_changes_since).and_return(Result.new(changes))

      # properties 001 and 002 is stubbed for client fetches,
      # 003, 004 and 005 stubbed for concierge database
      allow_any_instance_of(Waytostay::Client).to receive(:get_active_properties_by_ids) do |ids|
        properties = ids.collect do |ref|
          Roomorama::Property.load(
            Concierge::SafeAccessHash.new(
              JSON.parse(read_fixture("waytostay/properties/#{ref}.roomorama-attributes.json"))
            ))
        end
        Result.new properties
      end

      create_property(identifier: "003", host_id: host.id)
      create_property(identifier: "004", host_id: host.id)
      create_property(identifier: "005", host_id: host.id)
      create_property(identifier: "006", host_id: host.id)
    end

    describe "#perform" do
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

          # property "005" is known (was created on the database on the +before+
          # block), whereas "001" is not
          expect(subject).to receive(:sync_calendar).with("005")
          expect(subject).not_to receive(:sync_calendar).with("001")

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

      context "when rate limit is hit" do
        it "should stop making any more calls" do
          expect(subject.client).to receive(:get_active_properties_by_ids).once do
            Result.error(:http_status_429)
          end
          expect(subject.client).to_not receive(:update_media)
          subject.perform
        end
      end
    end

  end
end
