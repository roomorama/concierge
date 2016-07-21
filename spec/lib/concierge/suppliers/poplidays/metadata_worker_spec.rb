require 'spec_helper'

RSpec.describe Workers::Suppliers::Poplidays::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: Poplidays::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:properties_list) { JSON.parse(read_fixture('poplidays/lodgings.json')) }
  let(:property_details) { JSON.parse(read_fixture('poplidays/property_details.json')) }
  let(:availabilities) { JSON.parse(read_fixture('poplidays/availabilities_calendar.json')) }

  subject { described_class.new(host) }

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.error(:timeout_error) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq Poplidays::Client::SUPPLIER_NAME
    expect(error.code).to eq 'timeout_error'
  end

  context 'fetching property details' do
    before do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.error(:timeout_error) }
    end

    it 'announces an error if fetching property details fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Poplidays::Client::SUPPLIER_NAME
      expect(error.code).to eq 'timeout_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching availabilities' do
    before do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.error(:timeout_error) }
    end

    it 'announces an error if fetching description fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Poplidays::Client::SUPPLIER_NAME
      expect(error.code).to eq 'timeout_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
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

    it 'creates valid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect {
        subject.perform
      }.to change { PropertyRepository.count }.by(2)
    end
  end
end
