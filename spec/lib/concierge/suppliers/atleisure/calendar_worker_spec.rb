require 'spec_helper'

RSpec.describe Workers::Suppliers::AtLeisure::Calendar do
  include Support::Fixtures
  include Support::Factories

  before(:example) { create_property(host_id: host.id) }

  let(:supplier) { create_supplier(name: AtLeisure::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  subject { described_class.new(host) }

  context 'fetching availabilities' do
    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_availabilities) { Result.error(:json_rpc_response_has_errors) }
    end

    it 'announces an error if fetching availabilities fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq AtLeisure::Client::SUPPLIER_NAME
      expect(error.code).to eq 'json_rpc_response_has_errors'
    end

    it 'announces an error if some availability contains error' do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_availabilities) do
        Result.new([{'HouseCode' => '1', 'error' => 'HouseCode xx-1234-02 is unknown'}])
      end
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq AtLeisure::Client::SUPPLIER_NAME
      expect(error.code).to eq 'availability_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_availabilities) do
        Result.new([{'HouseCode' => '1', 'AvailabilityPeriodV1' => []}])
      end
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end
  end
end