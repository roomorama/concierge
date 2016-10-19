  require 'spec_helper'

RSpec.describe Workers::Suppliers::Avantio::Availabilities do
  include Support::Fixtures
  include Support::Factories

  before(:example) do
    create_property(
      identifier: '60505|1238513302|itsalojamientos', host_id: host.id
    )
  end

  let(:supplier) { create_supplier(name: Avantio::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  let(:descriptions) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Description.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        ['http://image.org/1'],
        'some description'
      )
    }
  end
  let(:occupational_rules) do
    {
      '204' => Avantio::Entities::OccupationalRule.new(
        '204',
        [
          Avantio::Entities::OccupationalRule::Season.new(
            Date.new(2016, 6, 10),
            Date.new(2017, 8, 10),
            2,
            1,
            (1..31).map(&:to_s),
            ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'],
            (1..31).map(&:to_s),
            ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']
          )
        ]
      )
    }
  end
  let(:rates) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Rate.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        [
          Avantio::Entities::Rate::Period.new(
            Date.new(2016, 6, 10),
            Date.new(2017, 8, 10),
            250.0
          )
        ]
      )
    }
  end

  let(:availabilities) do
    {
      '60505|1238513302|itsalojamientos' => Avantio::Entities::Availability.new(
        '60505',
        '1238513302',
        'itsalojamientos',
        '204',
        [
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 8, 24),
            DateTime.new(2014, 8, 27),
            'AVAILABLE'
          ),
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 8, 27),
            DateTime.new(2014, 8, 31),
            'UNAVAILABLE'
          ),
          Avantio::Entities::Availability::Period.new(
            DateTime.new(2014, 9, 11),
            DateTime.new(2020, 10, 16),
            'AVAILABLE'
          ),
        ]
      )
    }
  end

  let(:today) { Date.new(2016, 7, 14) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end


  subject { described_class.new(host) }

  context 'there are events from previous syncs in current context' do
    before do
      Concierge.context = Concierge::Context.new(type: 'batch')

      sync_process = Concierge::Context::SyncProcess.new(
        worker:     'metadata',
        host_id:    'UNRELATED_HOST',
        identifier: 'UNRELATED_PROPERTY'
      )
      Concierge.context.augment(sync_process)
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.error(:error) }
    end

    it 'announces an error without any unrelated context' do
      subject.perform
      error = ExternalErrorRepository.last
      expect(error.context.get('events').to_s).to_not include('UNRELATED_PROPERTY')
    end
  end

  context 'fetching rates' do
    it 'announces an error if fetching rates fails' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.error(:error) }

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'announces an error if rates not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new({}) }

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'rate_not_found'
      expect(error.description).to eq 'Rate for property `60505|1238513302|itsalojamientos` nof found'
    end
  end

  context 'fetching availabilities' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.error(:error) }
    end

    it 'announces an error if fetching availabilities fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'announces an error if availabilities not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new({}) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'availability_not_found'
      expect(error.description).to eq 'Availability for property `60505|1238513302|itsalojamientos` nof found'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'fetching occupational rules' do
    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.error(:error) }
    end

    it 'announces an error if fetching rules fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'error'
    end

    it 'announces an error if occupational rule not found for property' do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new({}) }

      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq Avantio::Client::SUPPLIER_NAME
      expect(error.code).to eq 'rule_not_found'
      expect(error.description).to eq 'Occupational rule for property `60505|1238513302|itsalojamientos` nof found'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  context 'success' do

    before do
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_rates) { Result.new(rates) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }
      allow_any_instance_of(Avantio::Importer).to receive(:fetch_occupational_rules) { Result.new(occupational_rules) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end
  end
end
