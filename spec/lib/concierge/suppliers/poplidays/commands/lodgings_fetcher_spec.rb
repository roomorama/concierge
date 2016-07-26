require 'spec_helper'

RSpec.describe Poplidays::Commands::LodgingsFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  subject { described_class.new(double(url: 'api.poplidays.com')) }

  describe '#call' do

    let(:lodgings_endpoint) { 'http://api.poplidays.com/v2/lodgings/out/Roomorama' }

    it 'returns result with error if internal error happend during remote call' do
      stub_call(:get, lodgings_endpoint) { raise Faraday::TimeoutError }
      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
    end

    it 'does not recognise the response if it returns an XML body instead' do
      stub_with_fixture(lodgings_endpoint, 'poplidays/unexpected_xml_response.xml')
      result = subject.call

      expect(result).not_to be_success
      expect(result.error.code).to eq :invalid_json_representation
    end

    it 'returns an array in success case' do
      stub_with_fixture(lodgings_endpoint, 'poplidays/lodgings.json')
      result = subject.call

      expect(result.success?).to be(true)
      expect(result.value).to be_an(Array)
      expect(result.value.length).to eq(2)
    end
  end

  def stub_with_fixture(endpoint, name)
    poplidays_response = read_fixture(name)
    stub_call(:get, endpoint) { [200, {}, poplidays_response] }
  end
end