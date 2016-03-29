require "spec_helper"

RSpec.describe Concierge::RequestLogger do
  class TestLoggerEngine
    attr_reader :logged_info

    def initialize
      @logged_info = []
    end

    def info(message)
      logged_info  << message
    end
  end

  let(:logger_engine) { TestLoggerEngine.new }
  subject { described_class.new(logger_engine) }

  describe "#log" do
    it "formats the request information" do
      subject.log(
        http_method: "POST",
        status:       200,
        path:         "/jtb/booking",
        time:         1.23,
        request_body: ""
      )

      expect(logger_engine.logged_info).to eq ["POST /jtb/booking | T: 1.23s | S: 200"]
    end

    it "includes the request body if there is any" do
      payload = { property_id: "123" }.to_json

      subject.log(
        http_method: "POST",
        status:       200,
        path:         "/jtb/booking",
        time:         1.23,
        request_body: payload
      )

      expect(logger_engine.logged_info).to eq ["POST /jtb/booking | T: 1.23s | S: 200\n#{payload}"]
    end
  end
end
