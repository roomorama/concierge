require "spec_helper"

RSpec.describe Web::Support::StatusCheck do
  include Support::HTTPStubbing

  let(:application_json) { { "Content-Type" => "application/json" } }
  let(:successful_response) {
    {
      "status"  => "ok",
      "time"    => "2016-05-14 05:58:56 UTC",
      "version" => "0.1.4"
    }.to_json
  }

  def concierge_responds_with
    stub_call(:get, "https://concierge.roomorama.com/_ping") { yield }
  end

  describe "#alive?" do
    it "is alive if the response is successful" do
      concierge_responds_with { [200, application_json, successful_response] }
      expect(subject).to be_alive
    end

    it "is not alive if concierge is unreachable" do
      concierge_responds_with { raise Faraday::TimeoutError }
      expect(subject).not_to be_alive
    end
  end

  describe "#healthy?" do
    it "is not healthy if concierge is unreachable" do
      concierge_responds_with { raise Faraday::TimeoutError }
      expect(subject).not_to be_healthy
    end

    it "is not healthy if the response status is not successful" do
      concierge_responds_with { [500, application_json, successful_response] }
      expect(subject).not_to be_healthy
    end

    it "is not healthy if the response is unrecognisable" do
      concierge_responds_with { [200, application_json, "<<<01010garbage#49%&"] }
      expect(subject).not_to be_healthy
    end

    it "is not healthy if the payload status does not indicate so" do
      response = JSON.parse(successful_response).merge("status" => "error").to_json
      concierge_responds_with { [200, application_json, response] }

      expect(subject).not_to be_healthy
    end

    it "is healthy if the response is as expected" do
      concierge_responds_with { [200, application_json, successful_response] }
      expect(subject).to be_healthy
    end
  end

  describe "#version" do
    it "is nil if concierge is unreachable" do
      concierge_responds_with { raise Faraday::TimeoutError }
      expect(subject.version).to be_nil
    end

    it "is nil if the response status is not successful" do
      concierge_responds_with { [500, application_json, successful_response] }
      expect(subject.version).to be_nil
    end

    it "is nil if the response is unrecognisable" do
      concierge_responds_with { [200, application_json, "<<<01010garbage#49%&"] }
      expect(subject.version).to be_nil
    end

    it "returns the value indicated in the response payload" do
      concierge_responds_with { [200, application_json, successful_response] }
      expect(subject.version).to eq "0.1.4"
    end
  end

  describe "#response" do
    it "returns the result of the ping request" do
      concierge_responds_with { [200, application_json, successful_response] }
      response = subject.response

      expect(response).to be_a Result
      expect(response).to be_success
      expect(response.value).to be_a Faraday::Response
    end
  end
end
