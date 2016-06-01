require "spec_helper"

RSpec.describe Workers::Synchronisation do
  include Support::Factories

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

  describe "#start" do
    it "pushes the property to processing if there are no errors" do
      operation = nil
      expect(subject).to receive(:enqueue) { |op| operation = op }

      subject.start("prop1") { Result.new(roomorama_property) }
      expect(operation).to be_a Roomorama::Client::Operations::Publish
      expect(operation.property).to eq roomorama_property
    end

    context "error handling" do
      let(:errors) { [] }
      before do
        Concierge::Announcer.on(Concierge::Errors::EXTERNAL_ERROR) do |params|
          errors << params
        end
      end

      it "announces an error if the property returned does not pass validations" do
        roomorama_property.images.first.identifier = nil
        subject.start("prop1") { Result.new(roomorama_property) }

        expect(errors.size).to eq 1
        error = errors.first
        expect(error[:operation]).to eq  "sync"
        expect(error[:supplier]).to eq "Supplier A"
        expect(error[:code]).to eq :missing_data
        expect(error[:message]).to eq "DEPRECATED"

        context = error[:context]
        expect(context[:version]).to eq  Concierge::VERSION
        expect(context[:host]).to eq Socket.gethostname
        expect(context[:type]).to eq "batch"
        expect(context[:events].first[:type]).to eq "sync_process"
        expect(context[:events].first[:identifier]).to eq "prop1"
        expect(context[:events].first[:host_id]).to eq host.id
        expect(context[:events].last[:error_message]).to eq "Invalid image object: identifier was not given, or is empty"
        expect(context[:events].last[:attributes]).to eq roomorama_property.to_h
      end

      it "announces an error if the property failed to be processed" do
        subject.start("prop1") { Result.error(:http_status_404) }

        expect(errors.size).to eq 1
        error = errors.first
        expect(error[:operation]).to eq "sync"
        expect(error[:supplier]).to eq "Supplier A"
        expect(error[:code]).to eq :http_status_404
        expect(error[:message]).to eq "DEPRECATED"

        context = error[:context]
        expect(context[:version]).to eq Concierge::VERSION
        expect(context[:type]).to eq "batch"
        expect(context[:events].size).to eq 1
        expect(context[:events].first[:type]).to eq "sync_process"
        expect(context[:events].first[:host_id]).to eq host.id
        expect(context[:events].first[:identifier]).to eq "prop1"
      end
    end
  end

  describe "#finish!" do
    it "does nothing if all known properties were processed" do
      subject.start("prop1") { Result.new(roomorama_property) }
      expect(subject).not_to receive(:enqueue)

      subject.finish!
    end

    it "does nothing if the synchronisation fails halfway" do
      subject.start("prop1") { Result.new(roomorama_property) }
      subject.start("prop2") { Result.error(:http_status_500) }
      subject.start("prop3") { Result.new(roomorama_property) }

      expect(subject).not_to receive(:enqueue)
      subject.finish!
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
      expect(subject).to receive(:enqueue) { |arg| operations << arg }.twice

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
  end
end
