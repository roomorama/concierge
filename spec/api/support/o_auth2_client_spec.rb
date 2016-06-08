require "spec_helper"

RSpec.describe API::Support::OAuth2Client do

  include Support::Fixtures
  include Support::HTTPStubbing

  let(:base_url) { "https://apis.waytostay.com" }
  let(:token_url) { "/oauth" }
  let(:client) { described_class.new({id: "id",
                                      secret: "secret",
                                      token_url: token_url,
                                      base_url: base_url}) }

  describe "#access_token" do
    before do
      client.oauth_client.connection = stub_call(:post, base_url + token_url,) {
        [200, {'Content-Type'=>'application/json'}, read_fixture("waytostay/oauth.json")]
      }
    end

    subject { client.access_token }
    it { expect(subject).to be_a(OAuth2::AccessToken) }
  end
end



