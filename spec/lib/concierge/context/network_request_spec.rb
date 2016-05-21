require "spec_helper"

RSpec.describe Concierge::Context::NetworkRequest do
  let(:params) {
    {
      method:       "post",
      url:          "https://maps.googleapis.com/geocode/json",
      query_string: "address=115%20Amoy%20St.",
      headers: {
        "Connection" => "keep-alive",
        "User-Agent" => "curl/7.0"
      },
      body: "request_body"
    }
  }

  subject { described_class.new(params) }

  describe "#to_h" do
    it "serializes the information to a valid hash" do
      expect(subject.to_h).to eq({
        type:        "network_request",
        http_method: "POST",
        url:         "https://maps.googleapis.com/geocode/json?address=115%20Amoy%20St.",
        headers: {
          "Connection" => "keep-alive",
          "User-Agent" => "curl/7.0"
        },
        body: "request_body"
      })
    end
  end
end
