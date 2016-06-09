require "spec_helper"

RSpec.describe API::Support::OAuth2Client do

  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { Concierge::Credentials.for("waytostay") }
  let(:client) { described_class.new({id: credentials[:client_id],
                                      secret: credentials[:client_secret],
                                      token_url: credentials[:token_url],
                                      base_url: credentials[:url]}) }

  before do
    client.oauth_client.connection = stub_call( :post,
                                               credentials[:url] + credentials[:token_url] ) {
      [200, {'Content-Type'=>'application/json'},
       read_fixture("waytostay#{credentials[:token_url]}.json")]
    }
  end

  describe "#access_token" do
    context "when successful" do

      subject { client.access_token }

      it { expect(subject).to be_a(OAuth2::AccessToken) }
      it { expect(subject.token).to be_a(String) }
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

      it { expect(subject.value).to be_a(Result) }
      it { expect(subject).to be_success }
    end

  end

  describe "#post" do
    let(:endpoint) { "/ping" }

    subject { client.post(endpoint, body:{message:"Hello World"}) }

    context "when successful" do
      before do
        client.oauth_client.connection = stub_call(:post,
                                                   credentials[:url] + endpoint ) {
          [200, {'Content-Type'=>'application/json'},
           read_fixture("waytostay#{endpoint}.post.json")]
        }
      end

      it { expect(subject.value).to be_a(Result) }
      it { expect(subject).to be_success }
    end
  end
end



