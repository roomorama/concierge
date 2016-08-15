require 'spec_helper'

RSpec.describe Workers::Suppliers::Ciirus::Calendar do
  include Support::Fixtures
  include Support::Factories

  before(:example) { create_property(host_id: host.id) }

  let(:supplier) { create_supplier(name: Ciirus::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }
  let(:rates) do
    [
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 6, 27),
        DateTime.new(2014, 8, 22),
        3,
        157.50
      ),
      Ciirus::Entities::PropertyRate.new(
        DateTime.new(2014, 8, 23),
        DateTime.new(2014, 10, 16),
        2,
        141.43
      )
    ]
  end
  let(:reservations) do
    [
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 8, 24),
        DateTime.new(2014, 8, 27),
        '6507374',
        false,
        nil
      ),
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 8, 27),
        DateTime.new(2014, 8, 31),
        '6525576',
        false,
        nil
      ),
      Ciirus::Entities::Reservation.new(
        DateTime.new(2014, 9, 11),
        DateTime.new(2014, 10, 16),
        '6507374',
        false,
        nil
      ),
    ]
  end

  subject { described_class.new(host) }

  context 'fetching rates' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching rates fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching reservations' do
    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_reservations) { Result.error(:soap_error) }
    end

    it 'announces an error if fetching reservations fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Ciirus::Client::SUPPLIER_NAME
      expect(error.code).to eq 'soap_error'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Ciirus::Importer).to receive(:fetch_reservations) { Result.new(reservations) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end
  end
end