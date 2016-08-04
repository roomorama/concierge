require 'spec_helper'

RSpec.describe Poplidays::Mappers::RoomoramaReservation do
  include Support::Fixtures

  let(:customer) do
    {
      first_name:  'John',
      last_name:   'Buttler',
      address:     'Long Island 100',
      email:       'my@email.com',
      phone:       '+3 675 45879',
    }
  end
  let(:params) do
    {
      property_id: '38180',
      check_in:    '2016-05-01',
      check_out:   '2016-05-12',
      guests:      3,
      subtotal:    2000,
      customer:    customer
    }
  end

  subject { described_class.new }
  let(:reservation) { subject.build(params, booking) }

  context 'for success response' do
    let(:booking) do
      {
        'id' => 9257079406,
        'reference' => 'CHD00001',
        'ruid' => 'f211687c1e88e065e3331cacebe4803c'
      }
    end

    it 'returns available roomorama quotation entity' do
      expect(reservation).to be_a(::Reservation)
      expect(reservation.check_in).to eq('2016-05-01')
      expect(reservation.check_out).to eq('2016-05-12')
      expect(reservation.guests).to eq(3)
      expect(reservation.property_id).to eq('38180')
      expect(reservation.reference_number).to eq('9257079406')
      expect(reservation.customer).to eq(customer)
    end
  end
end