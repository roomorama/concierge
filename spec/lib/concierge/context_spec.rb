require "spec_helper"

RSpec.describe Concierge::Context do
  let(:incoming_request) {
    Concierge::Context::IncomingRequest.new(
      method: "post",
      path: "/jtb/quote",
      query_string: "",
      headers: {
        "Connection"   => "keep-alive",
        "Content-Type" => "application/json"
      },
      body: " "
    )
  }

  let(:network_request) {
    Concierge::Context::NetworkRequest.new(
      method:       "post",
      url:          "https://www.jtbapi.com/api/booking",
      query_string: "check_in=2016-04-22&check_out=2016-04-26",
      headers: {
        "Connection"   => "keep-alive",
        "Content-Type" => "application/json"
      },
      body: "request_body"
    )
  }

  let(:network_failure) {
    Concierge::Context::NetworkFailure.new(
      message: "Connection timed out."
    )
  }

  describe "#augment" do
    it "includes the given event to the list of events of the context" do
      subject.augment(incoming_request)
      expect(subject.events).to eq [incoming_request]
    end
  end

  describe "#to_h" do
    before do
      allow(Time).to receive(:now) { Time.new("2016", "05", "21") }

      subject.augment(incoming_request)
      subject.augment(network_request)
      subject.augment(network_failure)
    end

    it "wraps the representation of all events plus metadata" do
      expect(subject.to_h).to eq({
        version: Concierge::VERSION,
        host:    Socket.gethostname,
        events: [
          {
            type:        "incoming_request",
            timestamp:   Time.now,
            http_method: "POST",
            headers: {
              "Connection"   => "keep-alive",
              "Content-Type" => "application/json"
            },
            body: " ",
            path: "/jtb/quote"
          },
          {
            type:        "network_request",
            timestamp:   Time.now,
            http_method: "POST",
            url:         "https://www.jtbapi.com/api/booking?check_in=2016-04-22&check_out=2016-04-26",
            headers: {
              "Connection"   => "keep-alive",
              "Content-Type" => "application/json"
            },
            body: "request_body"
          },
          {
            type:      "network_failure",
            timestamp: Time.now,
            message: "Connection timed out."
          }
        ]
      })
    end
  end
end
