require "spec_helper"

RSpec.describe API::Support::HTTPClient do
  include Support::HTTPStubbing

  let(:url) { "https://api.roomorama.com" }
  subject { described_class.new(url) }

  shared_examples "handling errors" do |http_method:|
    it "is successful if the underlying HTTP request succeeds" do
      stub_call(http_method, "/") { [200, {}, "OK"] }
      result = subject.public_send(http_method, "/")

      expect(result).to be_success
      response = result.value
      expect(response.body).to eq "OK"
    end

    # unfortunately Faraday does not have native timeout support on its
    # `test` adapter.
    it "fails when the connection times out" do
      stub_call(http_method, "/") { raise Faraday::TimeoutError }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it "fails when the connection cannot be performed" do
      stub_call(http_method, "/") { raise Faraday::ConnectionFailed.new("getaddrinfo returned -1") }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_failed
    end

    it "fails if there is an SSL issue" do
      stub_call(http_method, "/") { raise Faraday::SSLError.new("SSL error") }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :ssl_error
    end

    it "fails if there is any network issue during the request" do
      stub_call(http_method, "/") { raise Faraday::Error }
      result = subject.public_send(http_method, "/")

      expect(result).not_to be_success
      expect(result.error.code).to eq :network_failure
    end
  end

  describe "#get" do
    it_behaves_like "handling errors", http_method: :get
  end

  describe "#post" do
    it_behaves_like "handling errors", http_method: :post
  end

end
