require "spec_helper"

RSpec.describe Workers::PropertySynchronisation do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:host) { create_host }
  let(:roomorama_property) {
    Roomorama::Property.new("prop1").tap do |property|
      property.title        = "Studio Apartment"
      property.description  = "Largest Apartment in New York"
      property.nightly_rate = 100
      property.weekly_rate  = 200
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

  describe "#start" do
    it "pushes the property to processing if there are no errors" do
      operation = nil
      expect(subject).to receive(:run_operation) { |op| operation = op }

      subject.start("prop1") { Result.new(roomorama_property) }
      expect(operation).to be_a Roomorama::Client::Operations::Publish
      expect(operation.property).to eq roomorama_property
    end

    context "error handling" do
      it "announces an error if the property returned does not pass validations" do
        roomorama_property.images.first.identifier = nil
        subject.start("prop1") { Result.new(roomorama_property) }

        error = ExternalErrorRepository.last
        expect(error.operation).to eq  "sync"
        expect(error.supplier).to eq "Supplier A"
        expect(error.code).to eq "missing_data"

        context = error.context
        expect(context[:version]).to eq  Concierge::VERSION
        expect(context[:host]).to eq Socket.gethostname
        expect(context[:type]).to eq "batch"
        expect(context[:events].first["type"]).to eq "sync_process"
        expect(context[:events].first["identifier"]).to eq "prop1"
        expect(context[:events].first["host_id"]).to eq host.id
        expect(context[:events].last["error_message"]).to eq "Invalid image object: identifier was not given, or is empty"
        expect(context[:events].last["attributes"].keys).to eq roomorama_property.to_h.keys.map(&:to_s)
      end

      it "announces an error if the property failed to be processed" do
        subject.start("prop1") { Result.error(:http_status_404) }

        error = ExternalErrorRepository.last
        expect(error.operation).to eq "sync"
        expect(error.supplier).to eq "Supplier A"
        expect(error.code).to eq "http_status_404"

        context = error.context
        expect(context[:version]).to eq Concierge::VERSION
        expect(context[:type]).to eq "batch"
        expect(context[:events].size).to eq 1
        expect(context[:events].first["type"]).to eq "sync_process"
        expect(context[:events].first["host_id"]).to eq host.id
        expect(context[:events].first["identifier"]).to eq "prop1"
      end

      it "announces the error if the synchronisation with Roomorama fails" do
        stub_call(:post, "https://api.roomorama.com/v1.0/host/publish") {
          [422, {}, read_fixture("roomorama/invalid_type.json")]
        }

        expect {
          subject.start("prop1") { Result.new(roomorama_property) }
        }.to change { ExternalErrorRepository.count }.by(1)

        error = ExternalErrorRepository.last
        expect(error.operation).to eq "sync"
        expect(error.supplier).to eq "Supplier A"
        expect(error.code).to eq "http_status_422"
        expect(error.context[:type]).to eq "batch"
        types = error.context[:events].map { |h| h["type"] }
        expect(types).to eq ["sync_process", "network_request", "network_response"]
      end

      it "is successful if the API call succeeds" do
        stub_call(:post, "https://api.roomorama.com/v1.0/host/publish") {
          [201, {}, [""]]
        }

        expect {
          subject.start("prop1") { Result.new(roomorama_property) }
        }.not_to change { ExternalErrorRepository.count }
      end
    end
  end

  describe "#finish!" do
    before do
      stub_call(:post, "https://api.roomorama.com/v1.0/host/publish") { [201, {}, [""]] }
      stub_call(:put, "https://api.roomorama.com/v1.0/host/apply")    { [202, {}, [""]] }
    end

    it "does not purge if all known properties were processed" do
      subject.start("prop1") { Result.new(roomorama_property) }
      expect(subject).not_to receive(:run_operation)

      subject.finish!
    end

    it "does not purge if the synchronisation fails halfway" do
      subject.start("prop1") { Result.new(roomorama_property) }
      subject.start("prop2") { Result.error(:http_status_500) }
      subject.start("prop3") { Result.new(roomorama_property) }

      expect(subject).not_to receive(:run_operation)
      subject.finish!
    end

    it "does not purge if skip_purge! is invoked" do
      create_property(host_id: host.id, identifier: "prop1", data: roomorama_property.to_h)
      create_property(host_id: host.id, identifier: "prop2", data: roomorama_property.to_h.merge!(identifier: "prop2"))
      create_property(host_id: host.id, identifier: "prop3", data: roomorama_property.to_h.merge!(identifier: "prop3"))

      subject.skip_purge!
      subject.start("prop1") { Result.new(roomorama_property) }

      # properties +prop2+ and +prop3+ should be deleted if purging took place
      prop2 = PropertyRepository.from_host(host).identified_by("prop2").first
      expect(prop2).to be_a Property

      prop3 = PropertyRepository.from_host(host).identified_by("prop3").first
      expect(prop2).to be_a Property
    end

    it "enqueues a disable operation with non-processed identifiers" do
      data = {
        identifier: "prop1",
        images: [
          {
            identifier: "img1",
            url:        "https://www.example.org/img1.png"
          }
        ]
      }
      create_property(identifier: "prop1", host_id: host.id, data: data)
      create_property(identifier: "prop2", host_id: host.id + 1)
      create_property(identifier: "prop3", host_id: host.id)

      operations = []
      expect(subject).to receive(:run_operation) { |arg| operations << arg }.twice

      subject.start("prop1") { Result.new(roomorama_property) }
      subject.finish!

      expect(operations.size).to eq 2

      operation = operations.first
      expect(operation).to be_a Roomorama::Client::Operations::Diff
      expect(operation.property_diff.identifier).to eq "prop1"

      operation = operations.last
      expect(operation).to be_a Roomorama::Client::Operations::Disable
      expect(operation.identifiers).to eq ["prop3"]
    end

    it "announces the error in case the synchronisation with Roomorama fails" do
      stub_call(:delete, "https://api.roomorama.com/v1.0/host/disable") {
        [500, {}, [""]]
      }

      data = {
        identifier: "prop1",
        images: [
          {
            identifier: "img1",
            url:        "https://www.example.org/img1.png"
          }
        ]
      }
      create_property(identifier: "prop1", host_id: host.id, data: data)
      create_property(identifier: "prop2", host_id: host.id + 1)
      create_property(identifier: "prop3", host_id: host.id)

      subject.start("prop1") { Result.new(roomorama_property) }

      expect {
        subject.finish!
      }.to change { ExternalErrorRepository.count }.by(1)

      error = ExternalErrorRepository.last
      expect(error.context[:type]).to eq "batch"
      expect(error.context[:events].map { |h| h["type"] }).to eq(
        # 2 cycles of network_request/network_response: first to make an
        # update, the second to disable a property, triggering the +500+
        # error set up at the beginning of this example.
        ["sync_process", "network_request", "network_response", "network_request", "network_response"]
      )
    end

    it "creates a sync_process record when there is an error with the synchronisation" do
      subject.start("prop1") { Result.new(roomorama_property) }
      subject.start("prop2") { Result.error(:http_status_500) }
      subject.start("prop3") {
        # change the identifier so that it is recognised as a different property -
        # therefore, two properties should be created.
        roomorama_property.identifier = "prop3"
        Result.new(roomorama_property)
      }

      expect {
        subject.finish!
      }.to change { SyncProcessRepository.count }.by(1)

      sync = SyncProcessRepository.last
      expect(sync).to be_a SyncProcess
      expect(sync.host_id).to eq host.id
      expect(sync.successful).to eq false
      expect(sync.started_at).not_to be_nil
      expect(sync.finished_at).not_to be_nil
      expect(sync.properties_created).to eq 2
      expect(sync.properties_updated).to eq 0
      expect(sync.properties_deleted).to eq 0
    end

    it "registers updates and deletions when successful" do
      stub_call(:delete, "https://api.roomorama.com/v1.0/host/disable")    { [200, {}, [""]] }

      create_property(host_id: host.id, identifier: "prop1", data: roomorama_property.to_h)
      create_property(host_id: host.id, identifier: "prop2", data: roomorama_property.to_h.merge!(identifier: "prop2"))
      create_property(host_id: host.id, identifier: "prop3", data: roomorama_property.to_h.merge!(identifier: "prop3"))

      # no changes
      subject.start("prop1") { Result.new(roomorama_property) }

      # update
      subject.start("prop2") {
        roomorama_property.identifier = "prop2"
        roomorama_property.title = "Changed Title"
        Result.new(roomorama_property)
      }

      # create
      subject.start("prop4") {
        roomorama_property.identifier = "prop4"
        Result.new(roomorama_property)
      }

      # prop3 is not included - should be deleted
      #
      expect {
        subject.finish!
      }.to change { SyncProcessRepository.count }.by(1)

      sync = SyncProcessRepository.last
      expect(sync).to            be_a SyncProcess
      expect(sync.host_id).to    eq   host.id
      expect(sync.successful).to eq   true
      expect(sync.started_at).not_to  be_nil
      expect(sync.finished_at).not_to be_nil
      expect(sync.properties_created).to eq 1
      expect(sync.properties_updated).to eq 1
      expect(sync.properties_deleted).to eq 1
    end
  end
end
