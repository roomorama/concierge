require 'spec_helper'

RSpec.describe AtLeisure::Importer do
  include Support::Fixtures
  include Support::HTTPStubbing

  let(:credentials) { double(username: 'test', password: 'secret') }

  subject { described_class.new(credentials) }

  before do
    allow_any_instance_of(Concierge::JSONRPC).to receive(:request_id) { 888888888888 }
  end

  shared_examples 'handling errors' do
    it 'returns an unsuccessful result if external call fails' do
      stub_call(:post, endpoint) { raise Faraday::TimeoutError }

      expect(result).to be_a(Result)
      expect(result).to_not be_success
      expect(result.error.code).to eq :connection_timeout
      expect(result.error.data).to be_nil
    end
  end

  shared_examples 'success response' do
    it 'returns a list of data' do
      stub_call(:post, endpoint) { [200, {}, fixture] }
      expect(result.value).to be_an(Array)
    end
  end

  describe '#fetch_properties' do
    let(:endpoint) { 'https://listofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm' }
    let(:result) { subject.fetch_properties }
    let(:fixture) { jsonrpc_fixture('atleisure/properties_list.json') }

    it_behaves_like 'handling errors'
    it_behaves_like 'success response'
  end

  describe '#fetch_layout_items' do
    let(:endpoint) { 'https://referencelayoutitemsv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm' }
    let(:result) { subject.fetch_layout_items }
    let(:fixture) { jsonrpc_fixture('atleisure/layout_items.json') }

    it_behaves_like 'handling errors'
    it_behaves_like 'success response'

  end

  describe '#fetch_data' do
    let(:endpoint) { 'https://dataofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm' }
    let(:result) { subject.fetch_data([]) }
    let(:fixture) { jsonrpc_fixture('atleisure/property_data.json') }

    it_behaves_like 'handling errors'

    it 'returns hash in success case' do
      stub_call(:post, endpoint) { [200, {}, fixture] }
      result = subject.fetch_data([])

      expect(result.success?).to be true
      expect(result.value).to be_an(Hash)
    end
  end

  describe '#fetch_availabilities' do
    let(:endpoint) { 'https://dataofhousesv1.jsonrpc-partner.net/cgi/lars/jsonrpc-partner/jsonrpc.htm' }
    let(:result) { subject.fetch_availabilities([]) }
    # Here we can use fixtures from property_data method
    let(:fixture) { jsonrpc_fixture('atleisure/property_data.json') }

    it_behaves_like 'handling errors'

    it 'returns hash in success case' do
      stub_call(:post, endpoint) { [200, {}, fixture] }
      result = subject.fetch_availabilities([])

      expect(result.success?).to be true
      expect(result.value).to be_an(Hash)
    end
  end

  private

  def jsonrpc_fixture(name)
    {
      id:     888888888888,
      result: JSON.parse(read_fixture(name))
    }.to_json
  end

end
