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

      subject.report(event)

      expect(logger.reported_event).to eq event
    end
  end
end
