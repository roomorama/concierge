require "spec_helper"

RSpec.describe Audit::Client do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:base_url) { Concierge::Credentials.for('Audit')['host'] }
  subject { described_class.new }

  describe "#quote" do

    def quote_params_for(property_id)
      { property_id: property_id, check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    end

    it "returns the wrapped quotation from Audit::Price when successful" do
      json = JSON.parse(read_fixture('audit/quotation.success.json'))
      stub_call(:get, "#{base_url}/spec/fixtures/audit/quotation.success.json") {
        [200, {}, json.to_json]
      }

      quote_result = subject.quote(quote_params_for("success"))
      expect(quote_result).to be_success

      quote = quote_result.value
      expect(quote).to be_a Quotation
      expect(quote.total).to eq json['result']['total']
    end

    it "returns a Result with a generic error message on failure" do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/quotation.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }

      quote_result = subject.quote(quote_params_for("connection_timeout"))
      expect(quote_result).to_not be_success
      expect(quote_result.error.code).to eq :connection_timeout

      quote = quote_result.value
      expect(quote).to be_nil
    end
  end

  describe "#book" do
    def book_params_for(property_id)
      {
        property_id: property_id,
        check_in:    "2016-03-22",
        check_out:   "2016-03-24",
        guests:      2,
        subtotal:    300,
        customer:    {
          first_name:  "Alex",
          last_name:   "Black",
          country:     "India",
          city:        "Mumbai",
          address:     "first street",
          postal_code: "123123",
          email:       "test@example.com",
          phone:       "555-55-55",
        }
      }
    end

    it "returns the wrapped reservation from Audit::Booking when successful" do
      json = JSON.parse(read_fixture('audit/booking.success.json'))
      stub_call(:get, "#{base_url}/spec/fixtures/audit/booking.success.json") {
        [200, {}, json.to_json]
      }

      reservation_result = subject.book(book_params_for('success'))
      expect(reservation_result).to be_success

      reservation = reservation_result.value
      expect(reservation).to be_a Reservation
      expect(reservation.reference_number).to eq json['result']['reference_number']
    end

    it "returns a Result with a generic error message on failure" do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/booking.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }

      reservation_result = subject.book(book_params_for('connection_timeout'))
      expect(reservation_result).to_not be_success
      expect(reservation_result.error.code).to eq :connection_timeout
    end
  end

  describe "#cancel" do
    def cancel_params_for(reference_number)
      {
        reference_number: reference_number
      }
    end

    it "returns the wrapped reference_number when successful" do
      json = JSON.parse(read_fixture('audit/cancel.success.json'))
      stub_call(:get, "#{base_url}/spec/fixtures/audit/cancel.success.json") {
        [200, {}, json.to_json]
      }

      reservation_result = subject.cancel(cancel_params_for('success'))
      expect(reservation_result).to be_success

      expect(reservation_result.value).to eq json['result']
    end

    it "returns a Result with a generic error message on failure" do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/cancel.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }

      reservation_result = subject.cancel(cancel_params_for('connection_timeout'))
      expect(reservation_result).to_not be_success
      expect(reservation_result.error.code).to eq :connection_timeout
    end
  end
end
