require "spec_helper"

RSpec.describe Concierge::OAuth2Client do

  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { Concierge::Credentials.for("waytostay") }
  let(:client) { described_class.new(id: credentials[:client_id],
                                     secret: credentials[:client_secret],
                                     base_url: credentials[:url],
                                     token_url: credentials[:token_url]) }

  before do
    client.oauth_client.connection = stub_call(:post, credentials[:url] + credentials[:token_url] ) {
      [200, {'Content-Type'=>'application/json'},
        read_fixture("waytostay#{credentials[:token_url]}.json")]
    }
  end

  describe "#access_token" do
    subject { client.send(:access_token) }

    context "when successful" do
      it "should be a valid access_token" do
        expect(subject).to be_a(OAuth2::AccessToken)
        expect(subject.token).to be_a(String)
      end
    end

    context "with invalid credentials" do
      let(:client) { described_class.new(id: "invalid_id",
                                      secret: credentials[:client_secret],
                                      base_url: credentials[:url],
                                      token_url: "/invalid_credentials") }
      before do
        client.oauth_client.connection = stub_call(:post, credentials[:url] + "/invalid_credentials") {
          [400, {'Content-Type'=>'application/json'},
            read_fixture("waytostay/invalid_credentials.json")]
        }
      end
      it { expect{subject}.to raise_error(OAuth2::Error) }
    end
  end

  describe "#get" do

    let(:endpoint) { "/ping" }

    subject { client.get(endpoint, params:{page:1} ) }

    context "when successful" do
      before do
        client.oauth_client.connection = stub_call(:get, credentials[:url] + endpoint ) {
          [200, {'Content-Type'=>'application/json'},
           read_fixture("waytostay#{endpoint}.json")]
        }
      end

      it { expect(subject).to be_a(Result) }
      it { expect(subject).to be_success }
    end

    [
      { code: :http_status_404, response: lambda { [404, {}, "Not found"]}},
      { code: :http_status_500, response: lambda { [500, {}, "Server error"]}},
    ].each do |error|
      context "when error #{error[:code]} occur" do
        before do
          client.oauth_client.connection = stub_call(:get,
                                                     credentials[:url] + endpoint,
                                                     &error[:response])
        end
        it "should return a result with error coded #{error[:code]}" do
          expect(subject).to_not be_success
          expect(subject.error).to_not be_nil
          expect(subject.error.code).to eq error[:code]
        end
      end
    end

    context "when access_token in the cache expired" do
      let(:cache) { Concierge::Cache.new(namespace: "oauth2") }
      before do
        cache.fetch(credentials[:client_id],
                    serializer: Concierge::Cache::Serializers::JSON.new) do
          Result.new({"token_type"   => "BEARER",
                      "access_token" => "expired_token",
                      "expires_at"   => 1465467451})
        end
        client.oauth_client.connection = stub_call(:get, credentials[:url] + endpoint) {
          [401, {'Content-Type'=> 'application/json'}, "Token expired"]
        }
        # /oauth already stubbed to return the fixture with code 200
      end
      it "should request for new token and retry the request" do
        current_cache = cache.storage.read("oauth2.#{credentials[:client_id]}")
        expect(current_cache.value).to include "expired_token"

        expect(client.oauth_client).to receive(:client_credentials).and_call_original.exactly(2)
        subject
        current_cache = cache.storage.read("oauth2.#{credentials[:client_id]}")
        expect(current_cache).to be_nil
      end
    end

  end

  describe "#post" do
    let(:endpoint) { "/ping" }

    subject { client.post(endpoint,
                          body:{message:"Hello World"}.to_json,
                          headers: {'Content-Type'=>'application/json'}) }

    context "when successful" do
      before do
        client.oauth_client.connection = stub_call(:post,
                                                   credentials[:url] + endpoint,
                                                   body: {message: "Hello World"}.to_json,
                                                   strict:true) {
          [201, {'Content-Type'=>'application/json'},
           read_fixture("waytostay#{endpoint}.post.json")]
        }
      end

      it { expect(subject).to be_a(Result) }
      it { expect(subject).to be_success }
    end

    [
      { code: :http_status_404, response: lambda { [404, {}, "Not found"]}},
      { code: :http_status_401, response: lambda { [401, {}, "Not authorized"]}},
      { code: :http_status_415, response: lambda { [415, {}, "{\"type\":\"http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html\",\"title\":\"Unsupported Media Type\",\"status\":415,\"detail\":\"Invalid content-type specified\"}"]}},
    ].each do |error|
      context "when error #{error[:code]} occur" do
        before do
          client.oauth_client.connection = stub_call(:post,
                                                     credentials[:url] + endpoint,
                                                     &error[:response])
        end
        it "should return a result with error coded #{error[:code]}" do
          expect(subject).to_not be_success
          expect(subject.error).to_not be_nil
          expect(subject.error.code).to eq error[:code]
        end
      end
    end
  end
end

