require "spec_helper"

RSpec.describe AtLeisure::Client do
  let(:credentials) { double(username: "roomorama", password: "atleisure-roomorama") }

  subject { described_class.new(credentials) }

  describe "#quote" do
    let(:params) {
      { property_id: "AT-123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }

    it "returns the wrapped quotation from AtLeisure::Price when successful" do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(AtLeisure::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(AtLeisure::Price).to receive(:quote) { failed_operation }

      quote = subject.quote(params)
      expect(quote).to be_a Quotation
      expect(quote).not_to be_successful
      expect(quote.errors).to eq({ quote: "Could not quote price with remote supplier" })
    end
  end

  describe "#book" do
    let(:params) {
      {
        property_id: "A123",
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
    }

    it "returns the wrapped reservation from AtLeisure::Booking when successful" do
      successful_booking = Reservation.new(code: "XXX")
      allow_any_instance_of(AtLeisure::Booking).to receive(:book) { Result.new(successful_booking) }

      reservation = subject.book(params)

      expect(reservation).to be_a Reservation
      expect(reservation.code).to eq "XXX"
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(AtLeisure::Booking).to receive(:book) { failed_operation }

      reservation = subject.book(params)
      expect(reservation).to be_a Reservation
      expect(reservation).not_to be_successful
      expect(reservation.errors).to eq({ booking: "Could not create booking with remote supplier" })
    end
  end
end
