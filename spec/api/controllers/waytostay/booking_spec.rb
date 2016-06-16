require 'spec_helper'
require_relative "../shared/booking_validations"

RSpec.describe API::Controllers::Waytostay::Booking do
  include Support::HTTPStubbing

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

  it_behaves_like "performing booking parameters validations", controller_generator: -> { described_class.new }


  describe "#call" do

    let(:response) { parse_response(described_class.new.call(params)) }

    it "returns proper error if external request failed" do
      erred_reservation = Reservation.new(errors: { booking: "Could not create booking with remote supplier" })
      expect_any_instance_of(Waytostay::Client).to receive(:book).and_return(erred_reservation)

      expect(response.status).to eq 503
      expect(response.body["status"]).to eq "error"
      expect(response.body["errors"]["booking"]).to eq "Could not create booking with remote supplier"
    end

    it "returns a booking code when successful" do
      reservation = Reservation.new(params)
      reservation.code = "test_code"
      expect_any_instance_of(Waytostay::Client).to receive(:book).and_return(reservation)

      expect(response.status).to eq 200
      expect(response.body["status"]).to eq "ok"
      expect(response.body["code"]).to eq "test_code"
    end
  end
end
