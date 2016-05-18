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

  describe "#get" do
    it_behaves_like "handling errors", http_method: :get

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
