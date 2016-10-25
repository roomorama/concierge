require 'spec_helper'

RSpec.describe Workers::Suppliers::AtLeisure::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:properties_list) { JSON.parse(read_fixture('atleisure/properties_list.json')) }
  let(:success_result) { Result.new(properties_list * described_class::BATCH_SIZE) }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 6, 18))
  end

  subject { described_class.new(host) }

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { Result.error(:json_rpc_response_has_errors, 'test') }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq 'AtLeisure'
    expect(error.code).to eq 'json_rpc_response_has_errors'
    expect(error.description).to eq 'test'
  end

  context 'fetching data' do
    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_data) { Result.error(:invalid_json_rpc_response, 'test') }
    end

    it 'announces an error if fetching data fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq 'AtLeisure'
      expect(error.code).to eq 'invalid_json_rpc_response'
      expect(error.description).to eq 'test'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do
    let(:layout_items) { JSON.parse(read_fixture('atleisure/layout_items.json')) }
    let(:property_data) { JSON.parse(read_fixture('atleisure/property_data.json')) }
    let(:invalid_property_data) { JSON.parse(read_fixture('atleisure/property_with_mandatory_cost.json')) }

    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_layout_items) { Result.new(layout_items) }
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_data) { Result.new([property_data, invalid_property_data]) }
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

  context 'if at least one fetching data fails' do
    let(:layout_items) { JSON.parse(read_fixture('atleisure/layout_items.json')) }
    let(:property_data) { JSON.parse(read_fixture('atleisure/property_data.json')) }

    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_layout_items) { Result.new(layout_items) }
    end

    it 'skips purge' do
      properties_data = [
        Result.new([property_data, property_data]),
        Result.error(:error, 'Some error'),
        Result.new([property_data, property_data]),
        Result.new([property_data, property_data])

      ]
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_data) do
        properties_data.shift
      end

      expect_any_instance_of(Workers::PropertySynchronisation).to receive(:skip_purge!)
      subject.perform
    end
  end

end
