require 'spec_helper'
require_relative "../shared/book"
require_relative "../shared/quote"
require_relative "../shared/cancel"
require_relative "properties"
require_relative "media"
require_relative "availabilities"

RSpec.describe Waytostay::Client do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

  before do
    Concierge::Cache.new(namespace:"oauth2").
      fetch(stubbed_client.credentials[:client_id],
            serializer: Concierge::Cache::Serializers::JSON.new) do
      Result.new({"token_type"   => "BEARER",
                  "access_token" => "test_token",
                  "expires_at"   => Time.now.to_i + 10 * 3600 })
    end
    supplier = create_supplier(name: Waytostay::Client::SUPPLIER_NAME)
    create_host(supplier_id: supplier.id, fee_percentage: 7.0)
  end

  subject(:stubbed_client) { described_class.new }
  let(:base_url) { stubbed_client.credentials[:url] }

  it_behaves_like "Waytostay property client"

  it_behaves_like "Waytostay media client"

  it_behaves_like "Waytostay availabilities client"

  describe "#get_changes_since" do
    let(:changes_url) { base_url + Waytostay::Changes::ENDPOINT }

    before do
      stubbed_client.oauth2_client.oauth_client.connection =
        stub_call(:get, changes_url, params:{timestamp: timestamp}, strict: true) {
          [200, {}, read_fixture("waytostay/changes?timestamp=#{timestamp}.json")]
        }
    end

    subject { stubbed_client.get_changes_since(timestamp) }

    context "there are changes" do
      let(:timestamp) { 1466562548 }
      it "should return hash of changes by categories" do
        expect(subject.result[:properties]).to   match ["000001"]
        expect(subject.result[:media]).to        match ["002"]
        expect(subject.result[:availability]).to match ["003"]
      end
    end

    context "there are no changes" do
      let(:timestamp) { 1469599936 }
      it "should return empty arrays" do
        expect(subject.result[:properties]).to eq []
        expect(subject.result[:media]).to eq []
        expect(subject.result[:availability]).to eq []
      end
    end
  end

  describe "#book" do
    let(:book_url) { base_url + Waytostay::Book::ENDPOINT_BOOKING }
    let(:params) {{
      customer: {
        email:      "user@test.com",
        first_name: "john",
        last_name:  "last",
        phone:      "+12345678",
      },
      property_id:  "9234",
      inquiry_id:   "roomorama_inquiry_ref",
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
      agent_reference:    params[:inquiry_id],
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
    let(:successful_reference_number) { "KUFSHS" }

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
        "#{base_url}/bookings/#{successful_reference_number}/confirmation"
      ) {
        [200, {}, read_fixture("waytostay/bookings/#{successful_reference_number}/confirmation.json")]
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
        supplier_client.book(success_params)
      end

      it "should only send 1 post, book, when there're errors" do
        expect_any_instance_of(Concierge::OAuth2Client).to receive(:post).once.and_call_original
        result = supplier_client.book(error_params_list.first)
        expect(result.error.code).to eq :unrecognised_response
        expect(result.error.data).to eq "Missing keys: [\"booking_reference\"]"
      end

    end
  end

  describe "#quote" do
    let(:host) { create_host(fee_percentage: 7.0) }
    let(:quote_url) { base_url + Waytostay::Quote::ENDPOINT }

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
    let(:max_days_restriction_waytostay_params){ quote_post_body.merge(property_reference: "max_days_restriction") }
    let(:timeout_waytostay_params){ quote_post_body.merge(property_reference: "timeout") }
    let(:quote_responses){[
      { code: 200, body: success_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.json')},
      { code: 200, body: malformed_response_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.malformed.json')},
      { code: 422, body: unavailable_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.unavailable.json')},
      { code: 422, body: cutoff_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.cutoff.json')},
      { code: 422, body: max_days_restriction_waytostay_params.to_json, response: read_fixture('waytostay/bookings/quote.max_days_restriction.json')},
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


      %w(success unavailable less_than_min malformed_response,
         earlier_than_cutoff max_days_restriction timeout).each do |id|
        create_property(identifier: id, host_id: host.id)
      end
    end

    it_behaves_like "supplier quote method" do
      let (:supplier_client) { stubbed_client }
      let(:success_params) {
        { property_id: "success", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 }
      }
      let(:unavailable_params_list) {[
        success_params.merge(property_id: "unavailable")
      ]}
      let(:error_params_list) {[
        success_params.merge(property_id: "malformed_response"),
        success_params.merge(property_id: "timeout")
      ]}
    end

    it "appends net_rate and fee_percentage info" do
      quotation = stubbed_client.quote( { property_id: "success", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 } )
      expect(quotation.value.total).to eq 603.0
      expect(quotation.value.net_rate).to eq 563.55
      expect(quotation.value.host_fee_percentage).to eq 7
      expect(quotation.value.host_fee).to eq (603 - 563.55).round(2)
    end

    it "should announce missing fields from response for malformed responses" do
      quotation = stubbed_client.quote({ property_id: "malformed_response", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation).not_to be_success
      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "response_mismatch"
    end

    it "should return error when stay is less than minimum stay" do
      quotation = stubbed_client.quote({ property_id: "less_than_min", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation.error.code).to eq(:stay_too_short)
      expect(quotation.error.data).to eq("The minimum number of nights to book this apartment is 7")
    end

    it "should return error when check-in date is too near" do
      quotation = stubbed_client.quote({ property_id: "earlier_than_cutoff", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation.error.code).to eq(:check_in_too_near)
      expect(quotation.error.data).to eq("Selected check-in date is too near")
    end

    it "should return error when check-in date is too far" do
      quotation = stubbed_client.quote({ property_id: "max_days_restriction", check_in: Date.today + 10, check_out: Date.today + 20, guests: 2 })
      expect(quotation.error.code).to eq(:check_in_too_far)
      expect(quotation.error.data).to eq("Selected check-in date is too far")
    end
  end

  describe "#cancel" do
    let(:cancel_url) { stubbed_client.credentials[:url] + Waytostay::Cancel::ENDPOINT }
    let(:cancel_responses) {
      [
        { code: 422, id: "ABC", response: read_fixture('waytostay/bookings/KUFSHS/post.cancellation.not_confirmed.json')},
        { code: 200, id: "KUFSHS", response: read_fixture('waytostay/bookings/KUFSHS/post.cancellation.json')}
      ]
    }
    before do
      cancel_responses.each do |stub|
        url = cancel_url.gsub(":reference_number", stub[:id])
        stubbed_client.oauth2_client.oauth_client.connection =
          stub_call(:post, url){
            [stub[:code], {}, stub[:response]]
          }
      end
    end
    it_behaves_like "supplier cancel method" do
      let(:supplier_client) { stubbed_client }
      let(:success_params) { {reference_number: "KUFSHS" }}
      let(:error_params) { {reference_number: "ABC" }}
    end
  end
end

