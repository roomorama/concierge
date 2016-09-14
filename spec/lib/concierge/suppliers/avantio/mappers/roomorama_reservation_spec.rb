require 'spec_helper'

RSpec.describe Avantio::Mappers::RoomoramaReservation do

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

  let(:result_hash) do
    Concierge::SafeAccessHash.new({
      set_booking_rs: {
        localizer: {
          booking_code: '1457893325',
        }
      }
    })
  end

  context 'for valid result hash' do
    let(:reservation) { subject.build(params, result_hash) }

    it 'returns Reservation entity' do
      expect(reservation).to be_a(::Reservation)
    end

    it 'returns mapped reservation entity' do
      expect(reservation.check_in).to eq('2016-05-01')
      expect(reservation.check_out).to eq('2016-05-12')
      expect(reservation.guests).to eq(3)
      expect(reservation.property_id).to eq('38180')
      expect(reservation.reference_number).to eq('1457893325')
      expect(reservation.customer).to eq(customer)
    end
  end
end
