require 'spec_helper'

RSpec.describe Kigo::HostCheck do
  include Support::Fixtures
  include Support::HTTPStubbing
  include Concierge::JSON

  let(:credentials) { double(username: 'roomorama', password: '123') }
  let(:property_ids) { [1, 2] }
  let(:request_handler) { Kigo::LegacyRequest.new(credentials) }

  subject { described_class.new(property_ids, request_handler) }

  describe '#check' do
    let(:endpoint) { 'https://app.kigo.net/api/ra/v1/computePricing' }

    it 'returns true with successful response' do
      stub_call(:post, endpoint) { [200, {}, read_fixture('kigo/success.json')] }
      result = subject.active?

      expect(result).to be_success
      expect(result.value).to eq true
    end

    it 'is unsuccessful with failed response' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }
      result = subject.active?

      expect(result).not_to be_success
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end

    it 'returns false with response determined host as deactivated' do
      stub_call(:post, endpoint) { [200, {}, read_fixture('kigo/e_nosuch.json')] }
      result = subject.active?

      expect(result).to be_success
      expect(result.value).to eq false
    end

    it 'returns true when only 1 of the property returns successful response' do
      fail_params = subject.send(:fake_params, property_ids.first).value
      stub_call(:post, endpoint, body:json_encode(fail_params), strict: true) {
        [200, {}, read_fixture('kigo/e_nosuch.json')]
      }

      success_params = subject.send(:fake_params, property_ids.last).value
      stub_call(:post, endpoint, body:json_encode(success_params), strict: true) {
        [200, {}, read_fixture('kigo/success.json')]
      }

      result = subject.active?

      expect(result).to be_success
      expect(result.value).to eq true
    end
  end
end
