require 'spec_helper'

RSpec.describe Poplidays::Commands::Booking do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) do
    double(url: 'api.poplidays.com',
           client_key: '1111',
           passphrase: '4311')
  end
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
  let(:success_response) do
    '{
      "id": 9257079406,
      "reference": "CHD00001",
      "ruid": "f211687c1e88e065e3331cacebe4803c"
    }'
  end
  subject { described_class.new(credentials) }


  describe '#call' do

    let(:endpoint) { 'https://api.poplidays.com/v2/bookings/easy' }

    it 'returns result with error if internal error happend during remote call' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.call(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'does not recognise the response if it returns an XML body instead' do
      stub_with_fixture(endpoint, 'poplidays/unexpected_xml_response.xml')
      result = subject.call(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it 'returns a hash in success case' do
      stub_call(:post, endpoint) { [200, {}, success_response] }
      result = subject.call(params)

      expect(result.success?).to be(true)
      expect(result.value).to be_a(Hash)
    end
  end

  def stub_with_fixture(endpoint, name)
    poplidays_response = read_fixture(name)
    stub_call(:post, endpoint) { [200, {}, poplidays_response] }
  end
end