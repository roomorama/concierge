require 'spec_helper'

RSpec.describe THH::Commands::Cancel do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:url) { 'http://example.org' }
  let(:booking_id) { '30884' }
  let(:credentials) { double(key: 'Foo', url: url) }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        stub_call(:get, url) { raise Faraday::TimeoutError }

        result = subject.call(booking_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :connection_timeout
        expect(result.error.data).to be_nil
      end
    end

    context 'when xml response is correct' do
      it 'returns reference number' do
        stub_with_fixture('thh/cancel_response.xml')

        result = subject.call(booking_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to eq booking_id
      end
    end

    context 'when xml has unexpected structure' do
      it 'returns an error if no status field' do
        stub_with_fixture('thh/no_status_cancel_response.xml')

        result = subject.call(booking_id)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Cancel booking `30884` response does not contain `response.status` field')
      end

      it 'returns an error if unexpected status value' do
        stub_with_fixture('thh/unexpected_status_cancel_response.xml')

        result = subject.call(booking_id)

        expect(result).to be_a Result
        expect(result.success?).to be false
        expect(result.error.code).to eq(:unrecognised_response)
        expect(result.error.data).to eq('Cancel booking `30884` response contains unexpected value for `response.status` field: `false`')
      end
    end
  end

  def stub_with_fixture(name)
    response = read_fixture(name)
    stub_call(:get, url) { [200, {}, response] }
  end
end
