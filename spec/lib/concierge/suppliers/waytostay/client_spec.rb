require 'spec_helper'
require_relative '../shared/client_spec'

RSpec.describe Waytostay::Client do
  include Support::Fixtures
  include Support::HTTPStubbing

  before do
    Concierge::Cache.new(namespace:"oauth2").
      fetch(stubbed_client.credentials[:client_id],
            serializer: Concierge::Cache::Serializers::JSON.new) do
      Result.new({"token_type"=>"BEARER",
                  "access_token"=>"test_token",
                  "expires_at"=>1465467451})
    end
  end
  let(:fail_response) { read_fixture('waytostay/invalid_request.json') }

  subject(:stubbed_client) { described_class.new }

  describe '#quote' do

    let(:quote_url) { stubbed_client.credentials[:url] + described_class::ENDPOINTS[:quote] }
    let(:success_waytostay_params){
      { property_reference: 10, arrival_date: Date.today + 10, departure_date: Date.today + 20, number_of_adults: 2 }
    }
    let(:unavailable_waytostay_params){
      { property_reference: 20, arrival_date: Date.today + 10, departure_date: Date.today + 20, number_of_adults: 2 }
    }
    let(:cutoff_waytostay_params){
      { property_reference: 30, arrival_date: Date.today + 1, departure_date: Date.today + 10, number_of_adults: 2 }
    }
    let(:timeout_waytostay_params){
      { property_reference: 30, arrival_date: Date.today + 10, departure_date: Date.today + 80, number_of_adults: 2 }
    }
    let(:responses){[
      { code: 200, body: success_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.json')},
      { code: 422, body: unavailable_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.unavailable.json')},
      { code: 422, body: cutoff_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.cutoff.json')},
    ]}

    before do
      responses.each do |stub|
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:post, quote_url, params: stub[:params], body: stub[:body], strict: true) {
            [stub[:code], {}, stub[:response]]
          }
      end
      stubbed_client.oauth2_client.oauth_client.connection =
        stub_call(:post, quote_url, body: timeout_waytostay_params.to_json, strict: true) {
          raise Faraday::TimeoutError
        }
    end

    it_behaves_like "supplier quote method" do
      let (:supplier_client) { stubbed_client }
      let(:success_params) {
        { property_id: 10, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }
      }
      let(:unavailable_params) {
        { property_id: 20, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }
      }
      let(:error_params) {[
        { property_id: 30, check_in: Date.today + 1, check_out: Date.today + 10, guests: 2 }, # cutoff dates
        { property_id: 30, check_in: Date.today + 10, check_out: Date.today + 80, guests: 2 } # timeout
      ]}
    end
  end
end

