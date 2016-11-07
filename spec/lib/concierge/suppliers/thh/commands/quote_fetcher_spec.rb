require 'spec_helper'

RSpec.describe THH::Commands::QuoteFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:params) do
    API::Controllers::Params::Quote.new(
      property_id: '15',
      check_in: '2016-12-09',
      check_out: '2016-12-17',
    )
  end
  let(:credentials) { double(key: 'Foo', url: url) }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.call(params)

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns raw property' do
        stub_with_fixture('thh/availability_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an error' do
        stub_with_fixture('thh/invalid_availability_response.xml')

        result = subject.call(params)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Available response for params `{"property_id"=>"15", "check_in"=>"2016-12-09", "check_out"=>"2016-12-17"}` does not contain `response.available` field')
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
