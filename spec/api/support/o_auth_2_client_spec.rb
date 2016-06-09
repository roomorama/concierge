require "spec_helper"

RSpec.describe API::Support::OAuth2Client do

  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { Concierge::Credentials.for("waytostay") }
  let(:client) { described_class.new(id: credentials[:client_id],
                                     secret: credentials[:client_secret],
                                     base_url: credentials[:url],
                                     token_url: credentials[:token_url]) }

  before do
    client.oauth_client.connection = stub_call( :post,
                                               credentials[:url] + credentials[:token_url] ) {
      [200, {'Content-Type'=>'application/json'},
        read_fixture("waytostay#{credentials[:token_url]}.json")]
    }
  end

  describe "#access_token" do
    subject { client.send(:access_token) }

    context "when successful" do
      it "should be a valid access_token" do
        subject
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
        client.oauth_client.connection = stub_call( :post,
                                                   credentials[:url] + "/invalid_credentials") {
          [400, {'Content-Type'=>'application/json'},
            read_fixture("waytostay/invalid_credentials.json")]
        }
      end
      it { expect{subject}.to raise_error(OAuth2::Error) }
    end
  end

  describe "#get" do

    let(:endpoint) { "/ping" }

    subject { client.get(endpoint) }

    context "when successful" do
      before do
        client.oauth_client.connection = stub_call(:get,
                                                   credentials[:url] + endpoint ) {
          [200, {'Content-Type'=>'application/json'},
           read_fixture("waytostay#{endpoint}.json")]
        }
      end

      it { expect(subject).to be_a(Result) }
      it { expect(subject).to be_success }
    end

    {
      http_status_404: lambda { [404, {}, "Not found"] },
      http_status_401: lambda { [401, {}, "Not authorized"] },
    }.each do |code, error|
      context "when error #{code} occur" do
        before do
          client.oauth_client.connection = stub_call(:get,
                                     credentials[:url] + endpoint, &error)
        end
        it "should return a result with error coded #{code}" do
          expect(subject).to_not be_success
          expect(subject.error).to_not be_nil
          expect(subject.error.code).to eq code
        end
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
                                                   credentials[:url] + endpoint ) {
          [201, {'Content-Type'=>'application/json'},
           read_fixture("waytostay#{endpoint}.post.json")]
        }
      end

      it { expect(subject).to be_a(Result) }
      it { expect(subject).to be_success }
    end

    {
      http_status_404: lambda { [404, {}, "Not found"] },
      http_status_401: lambda { [401, {}, "Not authorized"] },
      http_status_415: lambda { [415, {}, "{\"type\":\"http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html\",\"title\":\"Unsupported Media Type\",\"status\":415,\"detail\":\"Invalid content-type specified\"}"] },
    }.each do |code, error|
      context "when error #{code} occur" do
        before do
          client.oauth_client.connection = stub_call(:post,
                                     credentials[:url] + endpoint, &error)
        end
        it "should return a result with error coded #{code}" do
          expect(subject).to_not be_success
          expect(subject.error).to_not be_nil
          expect(subject.error.code).to eq code
        end
      end
    end
  end
end

