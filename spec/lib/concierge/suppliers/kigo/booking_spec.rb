require 'spec_helper'

RSpec.describe Kigo::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double(subscription_key: '32933') }
  let(:params) {
    {
      property_id: '123',
      check_in:    '2016-03-22',
      check_out:   '2016-03-24',
      guests:      2,
      customer:    {
        first_name: 'Alex',
        last_name:  'Black',
        email:      'alex@black.com'
      }
    }
  }

  subject { described_class.new(credentials) }

  describe '#book' do
    let(:endpoint) { 'https://www.kigoapis.com/channels/v1/createConfirmedReservation' }

    it 'returns the underlying network error if any happened' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'returns a failure if the property ID given is not numerical' do
      params[:property_id] = 'KG-123'
      result               = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_property_id
    end

    it 'returns wrapped reservation with code if success' do
      stub_call(:post, endpoint) { [200, {}, read_fixture('kigo/success_booking.json')] }

      result = subject.book(params)

      expect(result).to be_success
      expect(result.value).to be_a Reservation
      expect(result.value.reference_number).to eq "24985"
    end
  end
end
