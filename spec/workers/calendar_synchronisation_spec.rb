require "spec_helper"

RSpec.describe Workers::CalendarSynchronisation do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:host) { create_host }
  let(:calendar) {
    Roomorama::Calendar.new("prop1").tap do |calendar|
      entry = Roomorama::Calendar::Entry.new(
        date:         "2016-04-22",
        available:    true,
        nightly_rate: 100,
        weekly_rate:  500
      )
      calendar.add(entry)

      entry = Roomorama::Calendar::Entry.new(
        date:         "2016-04-23",
        available:    false,
        nightly_rate: 100
      )
      calendar.add(entry)
    end
  }

  let(:empty_calendar) { Roomorama::Calendar.new("prop1") }

  subject { described_class.new(host) }

  describe "#start" do
    it "processes the calendar if there are no errors" do
      operation = nil
      expect(subject).to receive(:run_operation) { |op| operation = op }

      create_property(identifier: "prop1", host_id: host.id)
      subject.start("prop1") { Result.new(calendar) }

      expect(operation).to be_a Roomorama::Client::Operations::UpdateCalendar
      expect(operation.calendar).to eq calendar
    end

    it "does not run any operation for empty calendar" do
      expect(subject).to_not receive(:run_operation)

      create_property(identifier: "prop1", host_id: host.id)
      subject.start("prop1") { Result.new(empty_calendar) }
    end

    context "error handling" do
      it "announces an error if the calendar returned does not pass validations" do
        calendar.entries.first.date = nil

        create_property(identifier: "prop1", host_id: host.id)
        subject.start("prop1") { Result.new(calendar) }

        error = ExternalErrorRepository.last
        expect(error.operation).to eq  "sync"
        expect(error.supplier).to eq "Supplier A"
        expect(error.code).to eq "missing_data"

        context = error.context
        expect(context[:version]).to eq  Concierge::VERSION
        expect(context[:host]).to eq Socket.gethostname
        expect(context[:type]).to eq "batch"
        expect(context[:events].first["type"]).to eq "sync_process"
        expect(context[:events].first["worker"]).to eq "availabilities"
        expect(context[:events].first["identifier"]).to eq "prop1"
        expect(context[:events].first["host_id"]).to eq host.id
        expect(context[:events].last["error_message"]).to eq "Calendar validation error: One of the entries miss required parameters."
        expect(context[:events].last["attributes"].keys).to eq calendar.to_h.keys.map(&:to_s)
      end

      it "announces an error if the calendar to be processed with the supplier" do
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
        expect(context[:events].first["worker"]).to eq "availabilities"
        expect(context[:events].first["host_id"]).to eq host.id
        expect(context[:events].first["identifier"]).to eq "prop1"
      end

      it "announces the error if the calendar update with Roomorama fails" do
        stub_call(:put, "https://api.roomorama.com/v1.0/host/update_calendar") {
          [422, {}, read_fixture("roomorama/invalid_start_date.json")]
        }

        create_property(identifier: "prop1", host_id: host.id)

        expect {
          subject.start("prop1") { Result.new(calendar) }
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
        stub_call(:put, "https://api.roomorama.com/v1.0/host/update_calendar") {
          [202, {}, [""]]
        }

        expect {
          subject.start("prop1") { Result.new(calendar) }
        }.not_to change { ExternalErrorRepository.count }
      end

      it "skips calendar synchronisation if the property was not previously created by Concierge" do
        expect {
          subject.start("prop1") { Result.new(calendar) }
        }.not_to change { ExternalErrorRepository.count }

        expect(Roomorama::Client::Operations).not_to receive(:update_calendar)
      end
    end
  end

  describe "#finish!" do
    before do
      stub_call(:put, "https://api.roomorama.com/v1.0/host/update_calendar") { [202, {}, [""]] }
    end

    it "creates a sync_process record when there is an error with the synchronisation" do
      create_property(identifier: "prop1", host_id: host.id)
      create_property(identifier: "prop2", host_id: host.id)

      subject.start("prop1") { Result.new(calendar) }
      subject.start("prop2") { Result.error(:http_status_500) }

      expect {
        subject.finish!
      }.to change { SyncProcessRepository.count }.by(1)

      sync = SyncProcessRepository.last
      expect(sync).to be_a SyncProcess
      expect(sync.type).to eq "availabilities"
      expect(sync.host_id).to eq host.id
      expect(sync.successful).to eq true
      expect(sync.started_at).not_to be_nil
      expect(sync.finished_at).not_to be_nil
      expect(sync.stats[:properties_processed]).to eq 2
      expect(sync.stats[:available_records]).to eq 1
      expect(sync.stats[:unavailable_records]).to eq 1
    end
  end
end
