require "spec_helper"

RSpec.describe Kigo::Client do
  let(:credentials) { double(subscription_key: "beefdead") }

  subject { described_class.new(credentials) }

  describe "#quote" do
    let(:params) {
      { property_id: "123", check_in: "2016-03-22", check_out: "2016-03-25", guests: 2 }
    }

    it "returns the wrapped quotation from Kigo::Price when successful" do
      successful_quotation = Quotation.new(total: 999)
      allow_any_instance_of(Kigo::Price).to receive(:quote) { Result.new(successful_quotation) }

      quote_result = subject.quote(params)
      expect(quote_result).to be_success

      quote = quote_result.value
      expect(quote).to be_a Quotation
      expect(quote.total).to eq 999
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(Kigo::Price).to receive(:quote) { failed_operation }

      quote_result = subject.quote(params)
      expect(quote_result).to_not be_success
      expect(quote_result.error.code).to eq :something_failed

      quote = quote_result.value
      expect(quote).to be_nil
    end
  end

  describe "#book" do
    let(:params) {
      {
        property_id: '123',
        check_in:    '2016-03-22',
        check_out:   '2016-03-24',
        guests:      2,
        customer:    {
          first_name:   'Alex',
          last_name:    'Black',
          email:        'alex@black.com',
          phone_number: '777-77-77'
        }
      }
    }

    it "returns the wrapped reservation from Kigo::Booking when successful" do
      successful_reservation = Reservation.new(code: '123')
      allow_any_instance_of(Kigo::Booking).to receive(:book) { Result.new(successful_reservation) }

      reservation = subject.book(params)
      expect(reservation).to be_a Reservation
      expect(reservation.code).to eq '123'
    end

    it "returns a quotation object with a generic error message on failure" do
      failed_operation = Result.error(:something_failed)
      allow_any_instance_of(Kigo::Booking).to receive(:book) { failed_operation }

      reservation = subject.book(params)
      expect(reservation).to be_a Reservation
      expect(reservation).not_to be_successful
      expect(reservation.errors).to eq({ booking: 'Could not book property with remote supplier' })
    end
  end

end
