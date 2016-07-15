require 'spec_helper'

RSpec.describe Ciirus::Commands::ReservationsFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'example.org')
  end

  let(:property_id) { 38180 }

  let(:success_response) { read_fixture('ciirus/responses/reservations_response.xml') }
  let(:one_reservation_response) { read_fixture('ciirus/responses/one_reservation_response.xml') }
  let(:empty_response) { read_fixture('ciirus/responses/empty_reservations_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }
  subject { described_class.new(credentials) }

  describe '#call' do
    let(:many_reservations) do
       [
         Ciirus::Entities::Reservation.new(
           DateTime.new(2016, 7, 5),
           DateTime.new(2016, 7, 19),
           '6507374',
           false,
           nil
         ),
         Ciirus::Entities::Reservation.new(
           DateTime.new(2016, 7, 20),
           DateTime.new(2016, 7, 23),
           '6525576',
           false,
           nil
         )
       ]
    end

    let(:one_reservation) do
      [
        Ciirus::Entities::Reservation.new(
          DateTime.new(2016, 7, 5),
          DateTime.new(2016, 7, 19),
          '6507374',
          false,
          nil
        )
      ]
    end

    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when many reservations' do
      it 'returns array of reservations' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)
        reservations = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(reservations).to eq(many_reservations)
      end
    end

    context 'when one reservation' do
      it 'returns array with a reservation' do
        stub_call(method: described_class::OPERATION_NAME, response: one_reservation_response)

        result = subject.call(property_id)
        reservations = result.value

        expect(result).to be_a Result
        expect(result).to be_success
        expect(reservations).to eq(one_reservation)
      end
    end

    it 'returns empty array for empty response' do
      stub_call(method: described_class::OPERATION_NAME, response: empty_response)

      result = subject.call(property_id)
      reservations = result.value

      expect(result).to be_a Result
      expect(result).to be_success
      expect(reservations).to be_empty
    end
  end
end