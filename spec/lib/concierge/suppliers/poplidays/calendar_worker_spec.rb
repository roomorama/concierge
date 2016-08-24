require 'spec_helper'

RSpec.describe Workers::Suppliers::Poplidays::Calendar do
  include Support::Fixtures
  include Support::Factories

  before(:example) { create_property(host_id: host.id) }

  let(:supplier) { create_supplier(name: Poplidays::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:property_details) { parse_json(read_fixture('poplidays/property_details.json')) }
  let(:availabilities) { parse_json(read_fixture('poplidays/availabilities_calendar.json')) }

  before do
    allow(Date).to receive(:today).and_return(Date.new(2016, 6, 18))
  end

  subject { described_class.new(host) }

  context 'fetching property details' do
    before do
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
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_property_details) { Result.new(property_details) }
      allow_any_instance_of(Poplidays::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end
  end

  def parse_json(json_string)
    Yajl::Parser.parse(json_string)
  end
end
