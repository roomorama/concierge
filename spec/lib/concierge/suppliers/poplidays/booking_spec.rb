require "spec_helper"

RSpec.describe Poplidays::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Support::Factories

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
  let(:credentials) do
    double(url: 'api.poplidays.com',
           client_key: '1111',
           passphrase: '4311')
  end
  let(:success_response) do
    '{
      "id": 9257079406,
      "reference": "CHD00001",
      "ruid": "f211687c1e88e065e3331cacebe4803c"
    }'
  end

  let(:error_response) do
    '{
      "code": 409,
      "message": "Lodging is no more available",
      "ruid": "65a8930693af51afd5e90b0f3dfea805"
    }'
  end

  subject { described_class.new(credentials) }

  describe '#book' do
    let(:endpoint) { 'https://api.poplidays.com/v2/bookings/easy' }

    it 'returns the underlying network error if any happened in the call' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }

      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'does not recognise the response if it returns an XML body instead' do
      stub_with_fixture(endpoint, 'poplidays/unexpected_xml_response.xml')
      result = subject.book(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it 'returns not success result for poplidays error response and saves response' do
      stub_call(:post, endpoint) { [409, {}, error_response] }
      result = subject.book(params)

      expect(result).not_to be_success

      event = Concierge.context.events.last
      expect(event.to_h[:type]).to eq "network_response"
    end

    it 'returns mapped reservation' do
      stub_call(:post, endpoint) { [200, {}, success_response] }

      result = subject.book(params)

      expect(result).to be_success
      reservation = result.value

      expect(reservation).to be_a Reservation
      expect(reservation.check_in).to eq('2016-05-01')
      expect(reservation.check_out).to eq('2016-05-12')
      expect(reservation.guests).to eq(3)
      expect(reservation.property_id).to eq('38180')
      expect(reservation.reference_number).to eq('9257079406')
      expect(reservation.customer).to eq(customer)
    end

    def stub_with_fixture(endpoint, name)
      poplidays_response = read_fixture(name)
      stub_call(:post, endpoint) { [200, {}, poplidays_response] }
    end
  end
end
