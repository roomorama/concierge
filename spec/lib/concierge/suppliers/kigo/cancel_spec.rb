require 'spec_helper'

RSpec.describe Kigo::Cancel do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double(subscription_key: '32933') }
  let(:params) {
    { reference_number: 213 }
  }

  subject { described_class.new(credentials) }

  describe '#call' do
    let(:endpoint) { 'https://www.kigoapis.com/channels/v1/cancelReservation' }

    it 'returns the underlying network error if any happened' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.call(params)

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end


    it 'returns wrapped reference number if success' do
      stub_call(:post, endpoint) { [200, {}, read_fixture('kigo/cancel.json')] }

      result = subject.call(params)

      expect(result).to be_success
      expect(result.value).to eq 213
    end
  end
end
