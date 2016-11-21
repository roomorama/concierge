require "spec_helper"

RSpec.describe THH::Booking do
  include Support::Fixtures
  include Support::Factories

  let(:customer) do
    {
      first_name: 'John',
      last_name:  'Butler',
      email:      'john@email.com',
      phone:      '+3 5486 4560'
    }
  end

  let(:params) do
    API::Controllers::Params::Booking.new(
      property_id: '15',
      check_in:    '2016-12-09',
      check_out:   '2016-12-17',
      guests:      3,
      subtotal:    3000.0,
      customer:    customer
    )
  end
  let(:credentials) { double(key: 'Foo', url: 'http://example.org') }

  let(:success_response) do
    Concierge::SafeAccessHash.new({
      'villa_status'   => 'instant',
      'booking_status' => 'success',
      'booking_id'     => '80385',
      'booked_nights'  => '8',
      'price_total'    => '48,000',
      'currency'       => 'THB'
    })
  end

  subject { described_class.new(credentials) }

  describe '#book' do

    it 'returns the error if any happened in the command call' do
      allow_any_instance_of(THH::Commands::Booking).to receive(:call) { Result.error(:error, 'Some error') }

      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :error
      expect(result.error.data).to eq 'Some error'
    end

    it 'returns a special error if not availalbe response in the command call' do
      allow_any_instance_of(THH::Commands::Booking).to receive(:call) { Result.error(:not_available, 'Some error') }

      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :not_available
      expect(result.error.data).to eq 'Property not available for booking'
    end

    it 'returns mapped reservation' do
      allow_any_instance_of(THH::Commands::Booking).to receive(:call) { Result.new(success_response) }

      result = subject.book(params)

      expect(result).to be_success
      reservation = result.value

      expect(reservation).to be_a Reservation
      expect(reservation.check_in).to eq('2016-12-09')
      expect(reservation.check_out).to eq('2016-12-17')
      expect(reservation.guests).to eq(3)
      expect(reservation.property_id).to eq('15')
      expect(reservation.reference_number).to eq('80385')
      expect(reservation.customer).to eq(customer)
    end
  end
end
