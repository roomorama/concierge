require 'spec_helper'

RSpec.describe Ciirus::Mappers::RoomoramaReservation do

  let(:customer) do
    {
      first_name: 'John',
      last_name:  'Butler',
      email:      'john@email.com',
      phone:      '+3 5486 4560',
      address:    'Long Island 1245'
    }
  end

  let(:params) do
    API::Controllers::Params::Booking.new(
      property_id: 38180,
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          make_booking_response: {
            make_booking_result: {
              booking_placed: true,
              error_message: nil,
              booking_id: "873184",
              total_amount_including_tax: "2858.850000"
            }
          }
        }
      )
    end

    let(:reservation) { described_class.build(params, result_hash) }

    it 'returns mapped roomorama reservation entity' do
      expect(reservation).to be_a(::Reservation)
      expect(reservation.check_in).to eq('2016-05-01')
      expect(reservation.check_out).to eq('2016-05-12')
      expect(reservation.guests).to eq(3)
      expect(reservation.property_id).to eq('38180')
      expect(reservation.code).to eq('873184')
      expect(reservation.customer).to eq(customer)
    end
  end
end
