require 'spec_helper'

RSpec.describe Poplidays::Commands::QuoteFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) do
    double(url: 'api.poplidays.com',
           client_key: '1111',
           passphrase: '4311')
  end
  let(:params) do
    API::Controllers::Params::Quote.new(property_id: 33680,
                                        check_in: '2017-08-01',
                                        check_out: '2017-08-05',
                                        guests: 2)
  end
  let(:success_response) do
    '{
      "value": 3410.28,
      "ruid": "09cdecc64b5ba9504c08bb598075262f"
    }'
  end
  subject { described_class.new(credentials) }


  describe '#call' do

    let(:lodging_id) { '3245' }
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
      stub_with_string(endpoint, success_response)
      result = subject.call(params)

      expect(result.success?).to be(true)
      expect(result.value).to be_a(Hash)
    end
  end

  def stub_with_fixture(endpoint, name)
    poplidays_response = read_fixture(name)
    stub_call(:post, endpoint) { [200, {}, poplidays_response] }
  end

  def stub_with_string(endpoint, string)
    stub_call(:post, endpoint) { [200, {}, string] }
  end
end