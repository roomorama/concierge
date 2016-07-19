RSpec.shared_examples "Waytostay media client" do
  describe "#update_media" do

    let(:roomorama_property) { Roomorama::Property.load(
        # use this because #load expects keys in symbols
        Concierge::SafeAccessHash.new(
          JSON.parse(read_fixture("waytostay/properties/015868.roomorama-attributes.json"))
        )
      ).result
    }
    let(:media_url) { "#{base_url}/properties/#{roomorama_property.identifier}/media" }

    subject { stubbed_client.update_media(roomorama_property) }

    before do
      stubbed_client.oauth2_client.oauth_client.connection =
        stub_call(:get, media_url + "?page=2", strict: true) {
          [200, {}, read_fixture("waytostay/properties/015868/media?page=2.json")]
        }
      stubbed_client.oauth2_client.oauth_client.connection =
        stub_call(:get, media_url, strict: true) {
          [200, {}, read_fixture("waytostay/properties/015868/media.json")]
        }
    end

    it { expect(subject).to be_success }
    it { expect(subject.result.images.count).to eq(7 - 2) } # 2 invisible images
    it { expect(subject.result.validate!).to eq true }

    it "ignores waytostay caption (they are not descriptive)" do
      expect(subject.result.images.first.caption).to be_nil
    end

  end
end

