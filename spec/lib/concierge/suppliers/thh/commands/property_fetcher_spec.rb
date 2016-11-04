require 'spec_helper'

RSpec.describe THH::Commands::PropertyFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:property_id) { '15' }
  let(:credentials) do
    double(key: 'Foo',
           url: url)
  end

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns raw property' do
        stub_with_fixture('thh/property_response.xml')

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an error' do
        stub_with_fixture('thh/unexpected_response.xml')

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Property response for id `15` does not contain `response.property` field')
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
