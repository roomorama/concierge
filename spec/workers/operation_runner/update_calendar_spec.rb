require "spec_helper"

RSpec.describe Workers::OperationRunner::UpdateCalendar do
  include Support::Factories
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:host)     { create_host }
  let(:endpoint) { "https://api.staging.roomorama.com/v1.0/host/update_calendar" }
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
        date:         "2016-04-22",
        available:    false,
        nightly_rate: 100
      )
      calendar.add(entry)
    end
  }

  let(:operation) { Roomorama::Client::Operations.update_calendar(calendar) }
  let(:roomorama_client) { Roomorama::Client.new(host.access_token) }

  subject { described_class.new(operation, roomorama_client) }

  describe "#perform" do
    it "returns the underlying network problem, if any" do
      stub_call(:put, endpoint) { raise Faraday::TimeoutError }
      result = subject.perform(calendar)

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "saves the context information" do
      stub_call(:put, endpoint) { raise Faraday::TimeoutError }

      expect {
        subject.perform(calendar)
      }.to change { Concierge.context.events.size }

      event = Concierge.context.events.last
      expect(event).to be_a Concierge::Context::NetworkFailure
    end

    it "is unsuccessful if the API call fails" do
      stub_call(:put, endpoint) { [422, {}, read_fixture("roomorama/invalid_start_date.json")] }
      result = nil

      result = subject.perform(calendar)

      expect(result).to be_a Result
      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_422
    end

    it "returns the persisted property in a Result if successful" do
      stub_call(:put, endpoint) { [202, {}, [""]] }
      result = subject.perform(calendar)

      expect(result).to be_a Result
      expect(result).to be_success
    end
  end
end
