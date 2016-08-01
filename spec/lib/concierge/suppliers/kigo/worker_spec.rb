require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:properties_list) { JSON.parse(read_fixture('kigo/properties_list.json')) }
  let(:success_result) { Result.new(properties_list) }

  subject { described_class.new(host) }

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { Result.error(:json_rpc_response_has_errors) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq 'Kigo'
    expect(error.code).to eq 'json_rpc_response_has_errors'
  end

  it 'announces an error if fetching data fails' do
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
    allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.error(:connection_timeout) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.code).to eq 'connection_timeout'
    expect(error.supplier).to eq 'Kigo'
  end

  context 'success' do
    let(:property_data) { JSON.parse(read_fixture('kigo/property_data.json')) }
    let(:periodical_rates) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }
    let(:references) {
      {
        amenities: JSON.parse(read_fixture('kigo/amenities.json')),
        property_types: JSON.parse(read_fixture('kigo/property_types.json')),
      }
    }

    before do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.new(property_data) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(periodical_rates) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_references) { references }
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