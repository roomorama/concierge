require 'spec_helper'

RSpec.describe Workers::Suppliers::KigoCalendar do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let!(:property) { create_property(host_id: host.id) }

  subject { described_class.new(host) }

  before do
    allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
  end

  describe '#perform' do
    let(:prices) { JSON.parse(read_fixture('kigo/pricing_setup.json'))}
    let(:availabilities) { JSON.parse(read_fixture('kigo/availabilities.json'))}

    it 'performs according to response' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(prices) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

      expect { subject.perform }.to change {
        SyncProcessRepository.count
      }.by(1)

      sync_process = SyncProcessRepository.last
      expect(sync_process.host_id).to eq host.id
      expect(sync_process.type).to eq 'availabilities'

      stats = sync_process.stats

      expect(stats[:properties_processed]).to eq 1
      expect(stats[:available_records]).to eq 359
      expect(stats[:unavailable_records]).to eq 7
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

    it 'sets only availabilities' do
      empty_prices = { 'PRICING' => nil }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(empty_prices) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

      subject.perform

      sync_process = SyncProcessRepository.last

      expect(sync_process.host_id).to eq host.id
      expect(sync_process.type).to eq 'availabilities'

      stats = sync_process.stats

      expect(stats[:properties_processed]).to eq 1
      expect(stats[:available_records]).to eq 1
      expect(stats[:unavailable_records]).to eq 7
    end
  end

end