require "spec_helper"

RSpec.describe Concierge::Context::IncomingRequest do
  let(:params) {
    {
      method:       "post",
      path:         "/jtb/quote",
      query_string: "",
      headers: {
        "Host"       => "concierge.roomorama.com",
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
        type: "incoming_request",
        http_method: "POST",
        path: "/jtb/quote",
        headers: {
          "Host"       => "concierge.roomorama.com",
          "Connection" => "keep-alive",
          "User-Agent" => "curl/7.0"
        },
        body: "request_body"
      })
    end

    it "includes the query string if present" do
      params[:query_string] = "format=json"
      expect(subject.to_h[:path]).to eq "/jtb/quote?format=json"
    end
  end
end
