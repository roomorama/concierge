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
    end

    it "fails if the remote server is broken" do
      stub_call(http_method, url) { [500, {}, "Stack trace"] }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :http_status_500
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
          headers:      { "User-Agent" => "Roomorama/Concierge #{Concierge::VERSION}" },
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

    context "basic authentication" do
      let(:faraday_instance) { double("faraday") }

      before do
        allow(described_class).to receive(:_connection).and_return faraday_instance
      end

      context "with username & password" do
        let(:options) do
          {
            basic_auth: {
              username: user_name,
              password: password
            }
          }
        end

        let(:user_name) { "test_user" }
        let(:password) { "password_1" }


        it do
          expect(faraday_instance).to receive(:basic_auth).exactly(1).times
          expect(faraday_instance).not_to receive(:authorization)
          request_instance = described_class.new(url, options)
        end
      end

      context "with Authorization api key/token" do
        let(:options) do
          {
            basic_auth: {
              Authorization: "12345"
            }
          }
        end

        it do
          expect(faraday_instance).not_to receive(:basic_auth)
          expect(faraday_instance).to receive(:authorization).exactly(1).times
          request_instance = described_class.new(url, options)
        end
      end
    end
  end

  describe "#_connection" do
    it do
      # expect(described_class._connection).to be_nil
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

  describe "#put" do
    it_behaves_like "handling errors", http_method: :put

    it "returns the wrapped response object if successful" do
      stub_call(:put, [url, "/put/endpoint"].join) { [202, {}, "Accepted"] }
      result = subject.put("/put/endpoint")

      expect(result).to be_success
      response = result.value
      expect(response).to be_a Faraday::Response
      expect(response.body).to eq "Accepted"
    end
  end

  describe "#delete" do
    it_behaves_like "handling errors", http_method: :delete

    it "returns the wrapped response object if successful" do
      stub_call(:delete, [url, "/delete/endpoint"].join) { [202, {}, "Accepted"] }
      result = subject.delete("/delete/endpoint")

      expect(result).to be_success
      response = result.value
      expect(response).to be_a Faraday::Response
      expect(response.body).to eq "Accepted"
    end
  end

end
