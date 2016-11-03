require 'spec_helper'

RSpec.describe THH::Commands::PropertiesFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:credentials) do
    double(key: 'Foo',
           url: url)
  end

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.call

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns success array of properties' do
        stub_with_fixture('thh/properties_response.xml')

        result = subject.call

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to all(be_a Concierge::SafeAccessHash)
      end

      it 'can fetch many properties' do
        stub_with_fixture('thh/many_properties_response.xml')

        result = subject.call

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to all(be_a Concierge::SafeAccessHash)
        expect(result.value.length).to eq(2)
      end

      it 'returns empty array for empty response' do
        stub_with_fixture('thh/empty_properties_response.xml')

        result = subject.call

        properties = result.value
        expect(properties).to be_empty
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an error' do
        stub_with_fixture('thh/unexpected_response.xml')

        result = subject.call

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Response does not contain `response` field')
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
