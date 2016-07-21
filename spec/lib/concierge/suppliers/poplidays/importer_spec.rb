require 'spec_helper'

RSpec.describe Poplidays::Importer do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double }
  let(:property_id) { '35898794' }

  subject { described_class.new(credentials) }

  shared_examples 'handling errors' do
    it 'returns an unsuccessful result if external call fails' do
      stub_call(:get, endpoint) { raise Faraday::TimeoutError }

      expect(result).to be_a(Result)
      expect(result).to_not be_success
      expect(result.error.code).to eq :connection_timeout
    end
  end

  shared_examples 'success response' do
    it 'returns a success data' do
      stub_call(:get, endpoint) { [200, {}, fixture] }

      expect(result).to be_a(Result)
      expect(result).to be_success
    end
  end

  describe '#fetch_properties' do
    let(:endpoint) { 'http://api.poplidays.com/v2/lodgings/out/Roomorama' }
    let(:fixture) { read_fixture('poplidays/lodgings.json') }
    let(:result) { subject.fetch_properties }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_property_details' do
    let(:endpoint) { "https://api.poplidays.com/v2/lodgings/#{property_id}" }
    let(:fixture) { read_fixture('poplidays/property_details.json') }
    let(:result) { subject.fetch_property_details(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end

  describe '#fetch_availabilities' do
    let(:endpoint) { "https://api.poplidays.com/v2/lodgings/#{property_id}/availabilities" }
    let(:fixture) { read_fixture('poplidays/availabilities_calendar.json') }
    let(:result) { subject.fetch_availabilities(property_id) }

    it_behaves_like 'success response'
    it_behaves_like 'handling errors'
  end
end