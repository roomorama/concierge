require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Legacy do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'KigoLegacy') }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let(:properties_list) { JSON.parse(read_fixture('kigo/properties_list.json')) }
  let(:success_result) { Result.new(properties_list) }
  let(:references) {
    Result.new({
      amenities: JSON.parse(read_fixture('kigo/amenities.json')),
      property_types: JSON.parse(read_fixture('kigo/property_types.json')),
    })
  }

  subject { described_class.new(host) }

  context 'deactivated host' do

    before do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Kigo::HostCheck).to receive(:check) { Result.new(true) }
    end

    it 'announces an error with failed deletion' do
      expect(subject).to receive(:delete_host!) { Result.error(:connection_timeout) }
      expect(subject.synchronisation).not_to receive(:start)

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.code).to eq 'connection_timeout'
      expect(error.supplier).to eq 'KigoLegacy'
    end

    it 'deletes host if his properties deactivated' do
      expect(subject).to receive(:delete_host!) { Result.new(:host_has_deleted) }
      expect(subject.synchronisation).not_to receive(:start)
      subject.perform
    end

  end

  before do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_references) { references }
    allow_any_instance_of(Kigo::HostCheck).to receive(:check) { Result.new(false) }
  end

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { Result.error(:json_rpc_response_has_errors) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq 'KigoLegacy'
    expect(error.code).to eq 'json_rpc_response_has_errors'
  end

  it 'announces an error if fetching data fails' do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.error(:connection_timeout) }
    allow_any_instance_of(Kigo::HostCheck).to receive(:check) { Result.new(false) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.code).to eq 'connection_timeout'
    expect(error.supplier).to eq 'KigoLegacy'
  end

  it 'does not process properties with unknown host' do
    unknown_host = create_host(supplier_id: supplier.id, identifier: 'unknown')
    subject =  described_class.new(unknown_host)

    expect(subject.synchronisation).not_to receive(:finish!)
  end

  context 'success' do
    let(:property_data) { JSON.parse(read_fixture('kigo_legacy/property_data.json')) }
    let(:periodical_rates) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }

    before do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.new(property_data) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(periodical_rates) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end

    it 'doesnt create property with unsuccessful publishing' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'creates a property in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect {
        subject.perform
      }.to change { PropertyRepository.count }.by(1)
    end

  end

end