require 'spec_helper'
require_relative "../shared/book"
require_relative "../shared/quote"

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

  describe "fetch_property" do
    let(:property_id) { "015868" }
    let(:property_url) { stubbed_client.credentials[:url] + "/properties/#{property_id}" }
    before do
      stubbed_client.oauth2_client.oauth_client.connection = stub_call(:get, property_url) {
        [200, {}, read_fixture("waytostay/properties/#{property_id}.json")]
      }
    end

    subject { stubbed_client.fetch_property(property_id) }
    it "should return a Roomorama::Property" do
      expected_room_load = Roomorama::Property.load(
        Concierge::SafeAccessHash.new(
          JSON.parse(read_fixture("waytostay/properties/#{property_id}.roomorama-attributes.json"))
        )
      )
      room_without_images = expected_room_load.result.to_h
      room_without_images[:images] = []
      expect(subject.to_h).to match room_without_images
    end
  end

  describe "parse_number_of_beds" do
    subject { stubbed_client.send(:parse_number_of_beds, response) }
    context "when there are single and double sofa beds" do
      let(:response) {
        Concierge::SafeAccessHash.new( "general" => {
          "bedding_summary"=>[
            "1 single sofa bed",
            "2 double bed",
            "4 single bed",
            "1 double sofa bed"]}
        )
      }
      it { expect(subject[:number_of_double_beds]).to eq 2 }
      it { expect(subject[:number_of_single_beds]).to eq 4 }
      it { expect(subject[:number_of_sofa_beds]).to eq 2 }
    end
    context "when there are no signle sofa beds" do
      let(:response) {
        Concierge::SafeAccessHash.new( "general" => {
          "bedding_summary"=>[
            "2 double bed",
            "4 single bed",
            "1 double sofa bed"]}
        )
      }
      it { expect(subject[:number_of_sofa_beds]).to eq 1 }
    end
  end

  describe "#book" do
    let(:book_url) { stubbed_client.credentials[:url] + Waytostay::Book::ENDPOINT_BOOKING }
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
      number_of_adults:   params[:guests],
      payment_option:     "full_payment"
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
    let(:successful_code) { "KUFSHS" }

    before do
      booking_responses.each do |stub|
        stub_call(:post, book_url, body: stub[:body], strict: true) {
          [stub[:code], {}, stub[:response]]
        }
      end
      stub_call(:post, book_url, body: timeout_waytostay_params.to_json, strict: true) {
        raise Faraday::TimeoutError
      }
      # Need to assign the last stub call to be the oauth2 client connection.
      # Stubbing confirmation success
      stubbed_client.oauth2_client.oauth_client.connection = stub_call(
        :post,
        stubbed_client.credentials[:url] + "/bookings/#{successful_code}/confirmation"
      ) {
        [200, {}, read_fixture("waytostay/bookings/#{successful_code}/confirmation.json")]
      }
    end

    it_behaves_like "supplier book method" do
      let(:supplier_client) { stubbed_client }
      let(:success_params) { params.merge( { property_id: "1" } ) }
      let(:error_params_list) {[
        params.merge( { property_id: "2" } ),
        params.merge( { property_id: "21" } ),
        params.merge( { property_id: "22" } )
      ]}

      it "should send 2 posts, book and confirm" do
        expect_any_instance_of(Concierge::OAuth2Client).to receive(:post).twice.and_call_original
        reservation = supplier_client.book(success_params)
      end

      it "should only send 1 post, book, when there're errors" do
        expect_any_instance_of(Concierge::OAuth2Client).to receive(:post).once.and_call_original
        reservation = supplier_client.book(error_params_list.first)
      end

    end
  end

  describe "#quote" do

    let(:quote_url) { stubbed_client.credentials[:url] + Waytostay::Quote::ENDPOINT }

    let(:quote_post_body) {{
      property_reference: "1",
      arrival_date: Date.today + 10,
      departure_date: Date.today + 20,
      number_of_adults: 2,
      payment_option: "full_payment",
    }}
    let(:success_waytostay_params){ quote_post_body.merge(property_reference: "success") }
    let(:unavailable_waytostay_params){ quote_post_body.merge(property_reference: "unavailable") }
    let(:less_than_min_stay_waytostay_params){ quote_post_body.merge(property_reference: "less_than_min") }
    let(:malformed_response_waytostay_params){ quote_post_body.merge(property_reference: "malformed_response") }
    let(:cutoff_waytostay_params){ quote_post_body.merge(property_reference: "earlier_than_cutoff") }
    let(:timeout_waytostay_params){ quote_post_body.merge(property_reference: "timeout") }
    let(:quote_responses){[
      { code: 200, body: success_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.json')},
      { code: 200, body: malformed_response_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.malformed.json')},
      { code: 422, body: unavailable_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.unavailable.json')},
      { code: 422, body: cutoff_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.cutoff.json')},
      { code: 422, body: less_than_min_stay_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.less_than_min.json')},
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
        { property_id: "success", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }
      }
      let(:unavailable_params_list) {[
        success_params.merge(property_id: "unavailable"),
        success_params.merge(property_id: "less_than_min"),
        success_params.merge(property_id: "earlier_than_cutoff"),
      ]}
      let(:error_params_list) {[
        success_params.merge(property_id: "malformed_response"),
        success_params.merge(property_id: "timeout")
      ]}
    end

    it "should announce missing fields from response for malformed responses" do
      quotation = stubbed_client.quote({ property_id: "malformed_response", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation).not_to be_success
      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end
  end
end

