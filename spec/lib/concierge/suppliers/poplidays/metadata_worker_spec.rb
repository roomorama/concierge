require 'spec_helper'

RSpec.describe Workers::Suppliers::Poplidays::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: Poplidays::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:properties_list) { parse_json(read_fixture('poplidays/lodgings.json')) }
  let(:property_details) { parse_json(read_fixture('poplidays/property_details.json')) }
  let(:availabilities) { parse_json(read_fixture('poplidays/availabilities_calendar.json')) }
  let(:extras) { parse_json(read_fixture('poplidays/extras.json')) }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 6, 18))
  end

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

    it 'does not announces an error if property details is invalid' do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Validators::PropertyDetailsValidator).to receive(:valid?) { false }
      subject.perform

      error = ExternalErrorRepository.last

      expect(error).to be_nil
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

    it 'doesnt announce an error if availabilities is invalid' do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Poplidays::Validators::AvailabilitiesValidator).to receive(:valid?) { false }
      subject.perform

      error = ExternalErrorRepository.last

      expect(error).to be_nil
    end
  end

  context 'fetching cleaning extra' do
    before do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_extras) { Result.error(:timeout_error) }
    end

    context 'even without cleaning extra' do
      it 'finalizes synchronisation' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

        expect(subject.synchronisation).to receive(:finish!)
        subject.perform
      end

      it 'creates valid properties in database' do
        allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
        expect {
          subject.perform
        }.to change { PropertyRepository.count }.by(2)
      end
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_properties) { Result.new(properties_list) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_extras) { Result.new(extras) }
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

    it 'skip invalid properties' do
      allow_any_instance_of(Poplidays::Validators::PropertyValidator).to receive(:valid?) { false }
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end
  end

  def parse_json(json_string)
    Yajl::Parser.parse(json_string)
  end
end
