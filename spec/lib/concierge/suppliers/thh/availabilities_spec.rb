require 'spec_helper'

RSpec.describe Workers::Suppliers::THH::Availabilities do
  include Support::Fixtures
  include Support::Factories

  before(:example) { create_property(host_id: host.id) }

  let(:supplier) { create_supplier(name: THH::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  subject { described_class.new(host) }

  context 'fetching property' do
    before do
      allow_any_instance_of(THH::Importer).to receive(:fetch_property) { Result.error(:error, 'Some test') }
    end

    it 'announces an error if fetching property fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq THH::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
      expect(error.description).to eq 'Some test'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end


  context 'success' do

    let(:property) { read_property('thh/property_response.xml') }

    before do
      allow_any_instance_of(THH::Importer).to receive(:fetch_property) { Result.new(property) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end
  end

  def read_property(name)
    parser = Nori.new
    response = parser.parse(read_fixture(name))['response']
    Concierge::SafeAccessHash.new(response['property'])
  end
end
