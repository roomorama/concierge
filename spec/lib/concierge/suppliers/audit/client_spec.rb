require "spec_helper"
require_relative "../shared/book"
require_relative "../shared/quote"
require_relative "../shared/cancel"

RSpec.describe Audit::Client do
  include Support::HTTPStubbing
  include Support::Fixtures

  let(:base_url) { Concierge::Credentials.for('Audit')['host'] }
  subject { described_class.new }

  describe "#quote" do
    let(:success_json) { JSON.parse(read_fixture('audit/quotation.success.json')) }
    let(:unavailable_json) { JSON.parse(read_fixture('audit/quotation.unavailable.json')) }

    before do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/quotation.success.json") {
        [200, {}, success_json.to_json]
      }
      stub_call(:get, "#{base_url}/spec/fixtures/audit/quotation.unavailable.json") {
        [200, {}, unavailable_json.to_json]
      }
      stub_call(:get, "#{base_url}/spec/fixtures/audit/quotation.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }
    end

    def quote_params_for(property_id)
      { property_id: property_id, check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    end

    it "returns the wrapped quotation from Audit::Price when successful" do
      quote_result = subject.quote(quote_params_for("success"))
      expect(quote_result).to be_success

      quote = quote_result.value
      expect(quote).to be_a Quotation
      expect(quote.total).to eq success_json['result']['total']
    end

    it "returns a Result with a generic error message on failure" do
      quote_result = subject.quote(quote_params_for("connection_timeout"))
      expect(quote_result).to_not be_success
      expect(quote_result.error.code).to eq :connection_timeout

      quote = quote_result.value
      expect(quote).to be_nil
    end

    it_behaves_like "supplier quote method" do
      let(:supplier_client) { described_class.new }
      let(:success_params) { quote_params_for('success') }
      let(:unavailable_params_list) {[
        quote_params_for('unavailable'),
      ]}
      let(:error_params_list) {[
        quote_params_for('connection_timeout'),
      ]}
    end
  end

  describe "#book" do
    let(:success_json) { JSON.parse(read_fixture('audit/booking.success.json')) }

    before do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/booking.success.json") {
        [200, {}, success_json.to_json]
      }
      stub_call(:get, "#{base_url}/spec/fixtures/audit/booking.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }
    end

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
      reservation_result = subject.book(book_params_for('success'))
      expect(reservation_result).to be_success

      reservation = reservation_result.value
      expect(reservation).to be_a Reservation
      expect(reservation.reference_number).to eq success_json['result']['reference_number']
    end

    it "returns a Result with a generic error message on failure" do
      reservation_result = subject.book(book_params_for('connection_timeout'))
      expect(reservation_result).to_not be_success
      expect(reservation_result.error.code).to eq :connection_timeout
    end

    it_behaves_like "supplier book method" do
      let(:supplier_client) { described_class.new }
      let(:success_params) { book_params_for('success') }
      let(:successful_reference_number) { success_json['result']['reference_number'] }
      let(:error_params_list) {[
        book_params_for('connection_timeout'),
      ]}
    end
  end

  describe "#cancel" do
    let(:success_json) { JSON.parse(read_fixture('audit/cancel.success.json')) }

    before do
      stub_call(:get, "#{base_url}/spec/fixtures/audit/cancel.success.json") {
        [200, {}, success_json.to_json]
      }
      stub_call(:get, "#{base_url}/spec/fixtures/audit/cancel.connection_timeout.json") {
        raise Faraday::TimeoutError.new
      }
    end

    def cancel_params_for(reference_number)
      {
        reference_number: reference_number
      }
    end

    it "returns the wrapped reference_number when successful" do
      reservation_result = subject.cancel(cancel_params_for('success'))
      expect(reservation_result).to be_success

      expect(reservation_result.value).to eq success_json['result']
    end

    it "returns a Result with a generic error message on failure" do
      reservation_result = subject.cancel(cancel_params_for('connection_timeout'))
      expect(reservation_result).to_not be_success
      expect(reservation_result.error.code).to eq :connection_timeout
    end

    it_behaves_like "supplier cancel method" do
      let(:supplier_client) { described_class.new }
      let(:success_params) { cancel_params_for('success') }
      let(:error_params) { cancel_params_for('connection_timeout') }
    end
  end
end
