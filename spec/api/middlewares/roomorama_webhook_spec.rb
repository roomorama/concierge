require "spec_helper"

RSpec.describe API::Middlewares::RoomoramaWebhook do
  let(:roomorama_webhook) {
    {
      "action"  => "quote_instant",
      "event"   => "quote_instant",
      "inquiry" => {
        "id"                     => "12345",
        "flow"                   => "instant_booking",
        "base_rental"            => 735,
        "check_in"               => "2016-04-05",
        "check_out"              => "2016-04-08",
        "currency_code"          => "USD",
        "currency_symbol"        => "US$",
        "num_guests"             => 1,
        "extra_guests_surcharge" => 2205,
        "processing_fee"         => 50,
        "roomorama_fee"          => 462,
        "state"                  => "guest_to_pay",
        "tax"                    => 89,
        "subtotal"               => 3079,
        "total"                  => 3079,
        "updated_at"             => "2014-10-14T03:51:58Z",
        "created_at"             => "2014-10-14T03:51:58Z",
        "url"                    => "https://www.roomorama.com/host/inquiries/12345",
        "room" => {
          "id"          => 123789,
          "property_id" => "710387083",
          "unit_id"     => "JP32",
          "url"         => "https://www.roomorama.com/rooms/241364"
        },
        "user" => {
          "id"  => 123456,
          "url" => "https://www.roomorama.com/users/123456"
        },
        "host" => {
          "id"  => 12345,
          "url" => "https://www.roomorama.com/users/12345"
        }
      }
    }
  }
  let(:upstream) { lambda { |env| [200, {}, [concierge_response.to_json]] } }
  let(:app) { Rack::MockRequest.new(subject) }
  let(:request_body) { StringIO.new(roomorama_webhook.to_json) }
  let(:headers) {
    {
      input: request_body,
      "CONTENT_TYPE" => "application/json"
    }
  }

  describe "invalid webhooks" do
    context "invalid JSON request body" do
      let(:request_body) { StringIO.new("invalid json") }

      it "is not recognized" do
        expect(post("/", headers)).to eq invalid_webhook
      end
    end

    context "no event information" do
      before do
        roomorama_webhook.delete("event")
      end

      it "is not recognized" do
        expect(post("/", headers)).to eq invalid_webhook
      end
    end

    context "event is not expected" do
      before do
        roomorama_webhook["event"] = "unknown_event"
      end

      it "is not recognized" do
        expect(post("/", headers)).to eq invalid_webhook
      end
    end

    context "price_check event" do
      before do
        roomorama_webhook["event"] = "price_check"
      end

      it "is not recognized" do
        expect(post("/", headers)).to eq invalid_webhook
      end
    end
  end

  describe "cancelling bookings" do
    let(:concierge_response) {
      {
        status: "ok",
        cancelled_reference_number: "test_code"
      }
    }

    before do
      roomorama_webhook["action"] = "cancelled"
      roomorama_webhook["event"] = "cancelled"
      roomorama_webhook["inquiry"]["reference_number"] = "test_code"

    end

    it "returns 200 if upstream was success" do
      response = concierge_response.to_json
      expect(post("/", headers)).to eq [200, { "Content-Length" => response.size.to_s }, response]
    end

    it "returns 422 if upstream has error" do
      concierge_response[:status] = "error"
      concierge_response[:errors] = {"cancellation" => "Already cancelled"}
      response = concierge_response.to_json
      expect(post("/", headers)).to eq [422, { "Content-Length" => response.size.to_s }, response]
    end
  end

  describe "quoting bookings" do
    let(:concierge_response) {
      {
        status:      "ok",
        total:       150,
        currency:    "EUR",
        available:   true,
        property_id: "710387083",
        check_in:    "2016-04-05",
        check_out:   "2016-04-08",
        guests:      2
      }
    }

    it "returns a modified webhook with the correct information on success" do
      expect(post("/", headers)).to eq success_payload(total: 150, currency: "EUR")
    end

    it "returns the upstream (Concierge) response if the property is unavailable" do
      concierge_response[:available] = false
      response = concierge_response.to_json

      expect(post("/", headers)).to eq [422, { "Content-Length" => response.size.to_s }, response]
    end

    it "returns the upstream (Concierge) response if there was an error quoting the booking" do
      concierge_response[:status] = "error"
      response = concierge_response.to_json

      expect(post("/", headers)).to eq [422, { "Content-Length" => response.size.to_s }, response]
    end
  end

  describe "placing bookings" do
    let(:concierge_response) {
      {
        status: "ok",
        code: "1234",
        property_id: "710387083",
        unit_id: nil,
        check_in: "2016-04-05",
        check_out: "2016-04-08",
        guests: 2,
        customer: {
          first_name: "John",
          last_name: "Doe",
          gender: "Male"
        }
      }
    }

    before do
      roomorama_webhook["event"] = "booked_instant"
    end

    it "returns the upstream (Concierge) response on success" do
      response = concierge_response.to_json
      expect(post("/", headers)).to eq [200, { "Content-Length" => response.size.to_s }, response]
    end

    context "booking failure" do
      let(:upstream) { lambda { |env| [503, {}, [concierge_response.to_json]] } }

      it "returns the upstream (Concierge) response on error, with a non successful HTTP status" do
        concierge_response[:status] = "error"
        response = concierge_response.to_json

        expect(post("/", headers)).to eq [503, { "Content-Length" => response.size.to_s }, response]
      end
    end
  end

  subject { described_class.new(upstream) }

  def invalid_webhook
    [422, { "Content-Length" => "15" }, "Invalid webhook"]
  end

  def success_payload(total:, currency:)
    response = {
      "action"  => "quote_instant",
      "event"   => "quote_instant",
      "inquiry" => {
        "id"                     => "12345",
        "flow"                   => "instant_booking",
        "base_rental"            => total,
        "check_in"               => "2016-04-05",
        "check_out"              => "2016-04-08",
        "currency_code"          => currency,
        "currency_symbol"        => "US$",
        "num_guests"             => 1,
        "extra_guests_surcharge" => 0,
        "processing_fee"         => 0,
        "roomorama_fee"          => 462,
        "state"                  => "guest_to_pay",
        "tax"                    => 0,
        "subtotal"               => total,
        "total"                  => total,
        "updated_at"             => "2014-10-14T03:51:58Z",
        "created_at"             => "2014-10-14T03:51:58Z",
        "url"                    => "https://www.roomorama.com/host/inquiries/12345",
        "room" => {
          "id"          => 123789,
          "property_id" => "710387083",
          "unit_id"     => "JP32",
          "url"         => "https://www.roomorama.com/rooms/241364"
        },
        "user" => {
          "id"  => 123456,
          "url" => "https://www.roomorama.com/users/123456"
        },
        "host" => {
          "id"  => 12345,
          "url" => "https://www.roomorama.com/users/12345"
        }
      }
    }.to_json

    [200, { "Content-Length" => response.size.to_s }, response]
  end

  def get(path, headers = {})
    to_rack(app.get(path))
  end

  def post(path, params = {})
    to_rack(app.post(path, params))
  end

  def to_rack(response)
    [
      response.status,
      response.header,
      response.body
    ]
  end
end
