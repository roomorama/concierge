require 'spec_helper'

RSpec.describe Waytostay::Client do
  include Support::Fixtures
  include Support::HTTPStubbing

  before do
    Concierge::Cache.new(namespace:"oauth2").
      fetch(stubbed_client.credentials[:client_id],
            serializer: Concierge::Cache::Serializers::JSON.new) do
      Result.new({"token_type"   => "BEARER",
                  "access_token" => "test_token",
                  "expires_at"   => 1465467451})
    end
  end

  subject(:stubbed_client) { described_class.new }

  describe"#book" do
    let(:quote_url) { stubbed_client.credentials[:url] + Waytostay::Book::ENDPOINT }
    let(:params) {{
      customer: {
        email:      "user@test.com",
        first_name: "john",
        last_name:  "last",
        phone:      "+12345678",
      },
      property_id:  "9234",
      check_in:     "2016-06-10",
      check_out:    "2016-06-15",
      guests:       2
    }}
    let(:booking_post_body) {{
      email_address:      params[:customer][:email],
      name:               params[:customer][:first_name],
      surname:            params[:customer][:last_name],
      cell_phone:         params[:customer][:phone],
      language:           Waytostay::Book::DEFAULT_CUSTOMER_LANGUAGE,
      property_reference: params[:property_id],
      arrival_date:       params[:check_in],
      departure_date:     params[:check_out],
      number_of_adults:   params[:guests]
    }}
    let(:success_waytostay_params) { booking_post_body.merge(property_reference: "1") }
    let(:malformed_response_waytostay_params) { booking_post_body.merge(property_reference: "2") }
    let(:malformed_request_waytostay_params) { booking_post_body.merge(property_reference: "21") }
    let(:unavailable_waytostay_params) { booking_post_body.merge(property_reference: "22") }
    let(:timeout_waytostay_params) { booking_post_body.merge(property_reference: "3") }
    let(:booking_responses){[
      { code: 200, body: success_waytostay_params.to_json, response: read_fixture('waytostay/post.bookings.json')},
      { code: 200, body: malformed_response_waytostay_params.to_json, response: read_fixture('waytostay/post.bookings.malformed.json')},
      { code: 400, body: malformed_request_waytostay_params.to_json, response: read_fixture('waytostay/post.bookings.malformed_json.json')},
      { code: 422, body: unavailable_waytostay_params.to_json, response: read_fixture('waytostay/post.bookings.unavailable.json')},
    ]}

    before do
      booking_responses.each do |stub|
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:post, quote_url, body: stub[:body], strict: true) {
            [stub[:code], {}, stub[:response]]
          }
      end
      stubbed_client.oauth2_client.oauth_client.connection =
        stub_call(:post, quote_url, body: timeout_waytostay_params.to_json, strict: true) {
          raise Faraday::TimeoutError
        }
    end

    it_behaves_like "supplier book method" do
      let (:supplier_client) { stubbed_client }
      let(:success_params) { params.merge( { property_id: "1" } ) }
      let(:successful_code) { "KUFSHS" }
      let(:error_params_list) {[
        params.merge( { property_id: "2" } ),
        params.merge( { property_id: "21" } ),
        params.merge( { property_id: "22" } )
      ]}
    end
  end

  describe "#quote" do

    let(:quote_url) { stubbed_client.credentials[:url] + Waytostay::Quote::ENDPOINT }

    let(:success_waytostay_params){
      { property_reference: 10, arrival_date: Date.today + 10, departure_date: Date.today + 20, number_of_adults: 2 }
    }
    let(:malformed_response_waytostay_params){
      { property_reference: 11, arrival_date: Date.today + 10, departure_date: Date.today + 20, number_of_adults: 2 }
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
    let(:quote_responses){[
      { code: 200, body: success_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.json')},
      { code: 200, body: malformed_response_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.malformed.json')},
      { code: 422, body: unavailable_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.unavailable.json')},
      { code: 422, body: cutoff_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.cutoff.json')},
    ]}

    before do
      quote_responses.each do |stub|
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:post, quote_url, body: stub[:body], strict: true) {
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
      let(:error_params_list) {[
        { property_id: 11, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }, # malformed response
        { property_id: 30, check_in: Date.today + 1, check_out: Date.today + 10, guests: 2 }, # cutoff dates
        { property_id: 30, check_in: Date.today + 10, check_out: Date.today + 80, guests: 2 } # timeout
      ]}
    end

    it "should announce missing fields from response for malformed responses" do
      quotation = stubbed_client.quote({ property_id: 11, check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation).not_to be_successful
      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end
  end
end

