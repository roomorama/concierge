require 'spec_helper'

module Woori
  RSpec.describe Mappers::Reservation do
    include Concierge::JSON
    include Support::Fixtures

    let(:reservation_hash) do
      json = read_fixture("woori/entities/reservation_status/confirmed.json")
      result = json_decode(json)
      result.value
    end

    let(:reservation_params) do
      API::Controllers::Params::MultiUnitBooking.new(
        property_id: '1',
        unit_id: '9733',
        check_in: '2016-02-02',
        check_out: '2016-02-03',
        guests: 1,
        currency_code: 'EUR',
        subtotal: '123.45',
        customer: {
          first_name: 'Test',
          last_name: 'User',
          email: 'testuser@example.com',
          phone: '111-222-3333',
          display: 'Test User'
        }
      )
    end

    it "builds reservation object" do
      result_hash = Concierge::SafeAccessHash.new(reservation_hash)
      mapper = described_class.new(reservation_params, result_hash)
      reservation = mapper.build_reservation
      expect(reservation).to be_kind_of(::Reservation)
      expect(reservation.property_id).to eq("1")
      expect(reservation.unit_id).to eq("9733")
      expect(reservation.check_in).to eq("2016-02-02")
      expect(reservation.check_out).to eq("2016-02-03")
      expect(reservation.guests).to eq(1)
      expect(reservation.reference_number).to eq("w_WP20160729141224FE3E")
      expect(reservation.customer).to eq(
        {
          "first_name"=>"Test",
          "last_name"=>"User",
          "email"=>"testuser@example.com",
          "phone"=>"111-222-3333"
        }
      )
    end
  end
end
