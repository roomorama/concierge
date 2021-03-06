require "spec_helper"

RSpec.describe Concierge::JSONRPC do
  include Support::HTTPStubbing

  let(:url) { "https://api.roomorama.com/the/endpoint" }
  let(:request_id) { 888888888888 }
  subject { described_class.new(url) }

  before do
    allow(subject).to receive(:request_id) { request_id }
  end

  describe "#invoke" do
    context "handling errors" do
      it "redirects network errors back to the caller if the call cannot be performed" do
        stub_call(:post, url) { raise Faraday::TimeoutError }
        result = subject.invoke("anyMethod")

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
      end

      it "returns a proper error if the server returns an invalid JSON response" do
        stub_call(:post, url) { build_response("invalid json") }
        result = subject.invoke("anyMethod")

        expect(result).not_to be_success
        expect(result.error.code).to eq :invalid_json_representation
      end

      it "returns a proper error if the response ID does not match the request ID" do
        stub_call(:post, url) { build_response({ "id" => "111111111111" }.to_json) }
        result = nil

        expect {
          result = subject.invoke("anyMethod")
        }.to change { Concierge.context.events.size }

        expect(result).not_to be_success
        expect(result.error.code).to eq :json_rpc_response_ids_do_not_match

        event = Concierge.context.events.last
        expect(event.to_h[:type]).to eq "generic_message"
        expect(event.to_h[:label]).to eq "JSON-RPC Failure"
      end

      it "wraps the response error if any" do
        stub_call(:post, url) {
          build_response({ "id" => request_id, "error" => { "code" => "-32602", "message" => "Something went wrong"  } }.to_json)
        }
        result = nil

        expect {
          result = subject.invoke("anyMethod")
        }.to change { Concierge.context.events.size }

        expect(result).not_to be_success
        expect(result.error.code).to eq :json_rpc_response_has_errors

        event = Concierge.context.events.last
        expect(event.to_h[:type]).to eq "generic_message"
        expect(event.to_h[:label]).to eq "JSON-RPC Failure"
      end

      it "returns an error if there is no `error` or `result` elements" do
        stub_call(:post, url) { build_response({ "id" => request_id }.to_json) }
        result = nil

        expect {
          result = subject.invoke("anyMethod")
        }.to change { Concierge.context.events.size }

        expect(result).not_to be_success
        expect(result.error.code).to eq :invalid_json_rpc_response

        event = Concierge.context.events.last
        expect(event.to_h[:type]).to eq "generic_message"
        expect(event.to_h[:label]).to eq "JSON-RPC Failure"
      end
    end

    it "returns a successful result with the response data when all goes well" do
      stub_call(:post, url) {
        build_response({ "id" => request_id, "result" => { "Available" => true, "Price" => 100 } }.to_json)
      }

      expect_any_instance_of(Concierge::HTTPClient).to receive(:post).with("/the/endpoint", {
        jsonrpc: "2.0",
        id:      888888888888,
        method:  "anyMethod",
      }.to_json, {
        "Content-Type" => "application/json"
      }).and_call_original

      result = subject.invoke("anyMethod")

      expect(result).to be_success
      response = result.value
      expect(response).to eq({ "Available" => true, "Price" => 100 })
    end
  end

  def build_response(response)
    [200, {}, response]
  end
end
