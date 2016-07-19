RSpec.shared_examples "Waytostay availabilities client" do
  describe "#get_availabilities" do
    let(:property_identifier) { "015868" }
    let(:availability_url) { "#{base_url}/properties/#{property_identifier}/availability" }
    let(:rates_url) { "#{base_url}/properties/#{property_identifier}/rates" }

    subject { stubbed_client.get_availabilities(property_identifier) }

    context "succesful" do
      before do
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:get, availability_url, struct: true) {
            [200, {}, read_fixture("waytostay/properties/015868/availability.json")]
          }
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:get, availability_url + "?page=2", struct: true) {
            [200, {}, read_fixture("waytostay/properties/015868/availability?page=2.json")]
          }
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:get, rates_url + "?end_date=2018-07-03", struct: true) {
            [200, {}, read_fixture("waytostay/properties/015868/rates.json")]
          }
      end

      it "should be a successful list of calendar entries" do
        expect(subject).to be_success

        entries = subject.value
        entries.sort_by! {|entry| entry.date }
        expect(entries.first.date).to eq Date.parse("2016-06-20") # comes from rates api. See 015868/rates.json
        expect(entries.first.available).to eq true
        expect(entries.first.nightly_rate).to eq 95

        expect(entries.last.date).to eq Date.parse("2018-07-03")
        expect(entries.last.available).to eq false
        expect(entries.last.nightly_rate).to eq 100

        expect(entries.count - 1).to eq Date.parse("2018-07-03") - Date.parse("2016-06-20")
      end
    end

    context "malformed response" do
      before do
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:get, availability_url, struct: true) {
            [200, {}, read_fixture("waytostay/properties/015868/availability-malformed.json")]
          }
      end

      it "returns unrecognised_response Result if response is not recognised" do
        expect(subject).to_not be_success
        expect(subject.error.code).to eq :unrecognised_response
      end
    end
  end
end

