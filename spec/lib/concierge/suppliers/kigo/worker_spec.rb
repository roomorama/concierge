require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier }
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

  context 'success' do
    let(:layout_items) { JSON.parse(read_fixture('kigo/layout_items.json')) }
    let(:property_data) { JSON.parse(read_fixture('kigo/property_data.json')) }
    let(:invalid_property_data) { JSON.parse(read_fixture('kigo/property_with_mandatory_cost.json')) }

    before do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_layout_items) { Result.new(layout_items) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_data) { Result.new([property_data, invalid_property_data]) }
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