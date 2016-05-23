require "spec_helper"

RSpec.describe Concierge::HTTPClient do
  include Support::HTTPStubbing

  let(:url) { "https://api.roomorama.com" }
  subject { described_class.new(url) }

  shared_examples "handling errors" do |http_method:|
    it "is successful if the underlying HTTP request succeeds" do
      stub_call(http_method, url) { [200, {}, "OK"] }
      result = subject.public_send(http_method, "/")

      expect(result).to be_success
      response = result.value
      expect(response.body).to eq "OK"
    end

    # unfortunately Faraday does not have native timeout support on its
    # `test` adapter.
    it "fails when the connection times out" do
      stub_call(http_method, url) { raise Faraday::TimeoutError }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "fails when the connection cannot be performed" do
      stub_call(http_method, url) { raise Faraday::ConnectionFailed.new("getaddrinfo returned -1") }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_failed
    end

    it "fails if there is an SSL issue" do
      stub_call(http_method, url) { raise Faraday::SSLError.new("SSL error") }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :ssl_error
    end

    it "fails if there is any network issue during the request" do
      stub_call(http_method, url) { raise Faraday::Error }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :network_failure
    end

    it "fails if the endpoint is not found" do
      stub_call(http_method, url) { [404, {}, "Not Found"] }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_404
      expect(result.error.message).to eq "Not Found"
    end

    it "fails if the remote server is broken" do
      stub_call(http_method, url) { [500, {}, "Stack trace"] }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_500
      expect(result.error.message).to eq "Stack trace"
    end
  end

  shared_examples "request hooks" do |http_method:|
    class RequestRecorder
      attr_reader :requests, :responses, :errors

      def initialize
        @requests  = []
        @responses = []
        @errors    = []
      end

      def record_request(method, url, query_string, headers, body)
        requests << {
          method:       method,
          url:          url,
          query_string: query_string,
          headers:      headers,
          body:         body
        }
      end

      def record_response(status, headers, body)
        responses << {
          status:  status,
          headers: headers,
          body:    body
        }
      end

      def record_error(message)
        errors << {
          message: message
        }
      end
    end

    let(:recorder) { RequestRecorder.new }

    context "events" do
      it "works without changes" do
        stub_call(http_method, url) { [200, {}, "OK"] }
        result = subject.public_send(http_method, "/")

        expect(result).to be_success
        response = result.value
        expect(response.body).to eq "OK"
      end
    end

    context "listening to events" do
      before do
        Concierge::Announcer.on(Concierge::HTTPClient::ON_REQUEST) do |*args|
          recorder.record_request(*args)
        end

        Concierge::Announcer.on(Concierge::HTTPClient::ON_RESPONSE) do |*args|
          recorder.record_response(*args)
        end

        Concierge::Announcer.on(Concierge::HTTPClient::ON_FAILURE) do |*args|
          recorder.record_error(*args)
        end
      end

      it "runs the before/after request and response hooks" do
        stub_call(http_method, url) { [200, {}, "OK"] }
        result = subject.public_send(http_method, "/")

        expect(result).to be_success
        response = result.value
        expect(response.body).to eq "OK"

        expect(recorder.requests.size).to eq 1
        recorded = recorder.requests.first
        expect(recorded).to eq({
          method:       http_method,
          url:          [url, "/"].join,
          query_string: http_method == :get ? "" : nil,
          headers:      { "User-Agent" => "Faraday v0.9.2" },
          body:         http_method == :get ? nil : {}
        })

        expect(recorder.responses.size).to eq 1
        recorded = recorder.responses.first
        expect(recorded).to eq({
          status:  200,
          headers: {},
          body:    "OK"
        })
      end

      it "runs error hooks" do
        stub_call(http_method, url) { raise Faraday::ConnectionFailed.new("getaddrinfo returned -1") }
        result = subject.public_send(http_method, "/")

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_failed

        expect(recorder.errors.size).to eq 1
        recorded = recorder.errors.first
        expect(recorded).to eq({
          message: "getaddrinfo returned -1"
        })
      end
    end

  end

  describe "#get" do
    it_behaves_like "handling errors", http_method: :get
    it_behaves_like "request hooks",   http_method: :get

    it "returns the wrapped response object if successful" do
      stub_call(:get, [url, "/get-endpoint"].join) { [200, {}, "OK"] }
      result = subject.get("/get-endpoint")

      expect(result).to be_success
      response = result.value
      expect(response).to be_a Faraday::Response
      expect(response.body).to eq "OK"
    end
  end

  describe "#post" do
    it_behaves_like "handling errors", http_method: :post
    it_behaves_like "request hooks",   http_method: :post

    it "returns the wrapped response object if successful" do
      stub_call(:post, [url, "/post/endpoint"].join) { [201, {}, nil] }
      result = subject.post("/post/endpoint")

      expect(result).to be_success
      response = result.value
      expect(response).to be_a Faraday::Response
      expect(response.body).to be_nil
    end
  end

end
