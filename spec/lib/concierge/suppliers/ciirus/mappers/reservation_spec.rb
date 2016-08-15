require 'spec_helper'

RSpec.describe Ciirus::Mappers::Reservation do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          arrival_date: DateTime.new(2014, 6, 27),
          departure_date: DateTime.new(2014, 8, 22),
          booking_id: '3554879',
          has_pool_heat: false,
          guest_name: 'John'
        }
      )
    end

    subject { described_class.new }

    it 'returns mapped reservation entity' do
      reservation = subject.build(result_hash)
      expect(reservation).to be_a(Ciirus::Entities::Reservation)
      expect(reservation.arrival_date).to eq(DateTime.new(2014, 6, 27))
      expect(reservation.departure_date).to eq(DateTime.new(2014, 8, 22))
      expect(reservation.booking_id).to eq('3554879')
      expect(reservation.has_pool_heat).to be_falsey
      expect(reservation.guest_name).to eq('John')
    end
  end

end
