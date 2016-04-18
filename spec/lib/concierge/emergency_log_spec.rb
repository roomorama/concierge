require "spec_helper"

RSpec.describe Concierge::EmergencyLog do
  class TestLogger
    attr_reader :reported_event

    def error(event)
      @reported_event = event
    end
  end

  let(:logger) { TestLogger.new }

  before do
    Concierge::EmergencyLog.logger = logger
  end

  describe "#report" do
    it "logs the information contained in the event passsed and triggers a Rollbar notification" do
      expect(Rollbar).to receive(:critical).with("Emergency Log: some_error")
      event = Concierge::EmergencyLog::Event.new("some_error", "A very serious error happened", ["Backtrace"])
      allow(Time).to receive(:now) { Time.new("2016", "04", "18", "10", "37", "12") }

      subject.report(event)

      serialized_event = event.to_h.merge({
        timestamp: "2016-04-18 10:37:12 +0000",
        messages: ["Backtrace"]
      })
      expect(logger.reported_event).to eq serialized_event.to_json
    end
  end
end
