require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Legacy::Calendar do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:identifier) { '123' }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let!(:property) { create_property(host_id: host.id, identifier: identifier) }

  subject { described_class.new(host, [identifier]) }

  before do
    allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
  end

  describe '#perform' do
    let(:today) { Date.today }
    let(:days_count) { 5 }
    let(:prices) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }
    let(:reservations) {
      [{
         'RES_CHECK_IN'  => "#{today} 14:00",
         'RES_CHECK_OUT' => "#{today + days_count} 11:00"
       }]
    }

    it 'performs according to response' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(prices) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_reservations) { Result.new(reservations) }

      expect { subject.perform }.to change {
        SyncProcessRepository.count
      }.by(1)

      sync_process = SyncProcessRepository.last
      expect(sync_process.host_id).to eq host.id
      expect(sync_process.type).to eq 'availabilities'

      stats = sync_process.stats

      expect(stats[:properties_processed]).to eq 1
      expect(stats[:available_records]).to eq 361
      expect(stats[:unavailable_records]).to eq days_count
    end

    it 'does not process property with external error' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.error(:connection_timeout) }

      subject.perform

      sync_process = SyncProcessRepository.last

      expect(sync_process.host_id).to eq host.id
      expect(sync_process.type).to eq 'availabilities'

      stats = sync_process.stats

      expect(stats[:properties_processed]).to eq 1
      expect(stats[:available_records]).to eq 0
      expect(stats[:unavailable_records]).to eq 0
    end

  end

end