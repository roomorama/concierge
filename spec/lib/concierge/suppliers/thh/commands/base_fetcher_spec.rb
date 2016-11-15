require 'spec_helper'

RSpec.describe THH::Commands::BaseFetcher do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:credentials) { double(key: 'Foo', url: url) }
  let(:params) { {} }

  before do
    allow(subject).to receive(:action).and_return('some_action')
  end

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.api_call(params)

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns success a hash' do
        stub_with_fixture('thh/properties_response.xml')

        result = subject.api_call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an empty hash for empty response' do
        stub_call(:get, url) { [200, {}, ''] }

        result = subject.api_call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
        expect(result.value.to_h).to be_empty
      end

      it 'returns restored xml for invalid xml' do
        stub_call(:get, url) { [200, {}, '<a><b></a></b>invalid xml'] }

        result = subject.api_call(params)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Concierge::SafeAccessHash
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
