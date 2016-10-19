require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Calendar do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:identifier) { '123' }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let(:property_attrs) {{ host_id: host.id, identifier: identifier }}
  let!(:property) { create_property(property_attrs) }

  subject { described_class.new(host, [identifier]) }

  before do
    allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
  end

  describe '#perform' do
    let(:prices) { JSON.parse(read_fixture('kigo/pricing_setup.json')) }
    let(:availabilities) { JSON.parse(read_fixture('kigo/availabilities.json')) }

    it 'finishes successfully if there are no identifiers to be synchronised' do
      subject = described_class.new(host, [])

      expect {
        subject.perform
      }.to change { SyncProcessRepository.count }.by(1)

      sync_process = SyncProcessRepository.last
      expect(sync_process.host_id).to eq host.id
      expect(sync_process.stats[:properties_processed]).to eq 0
      expect(sync_process.stats[:available_records]).to eq 0
      expect(sync_process.stats[:unavailable_records]).to eq 0
    end

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
      expect(stats[:available_records]).to eq 358
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

    context "when pricing is empty" do
      let(:empty_prices) {{ 'PRICING' => nil }}

      context "when property has minimum_stay value" do
        let(:property_attrs) {{ host_id: host.id, identifier: identifier, data: { minimum_stay: 13, nightly_rate: 10 }}}

        it 'sets only availabilities' do
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

      context "when property has no minimum_stay value" do
        let(:property_attrs) {{ host_id: host.id, identifier: identifier, data: { minimum_stay: nil, nightly_rate: 10 }}}

        it "returns external error" do
          allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices) { Result.new(empty_prices) }
          allow_any_instance_of(Kigo::Importer).to receive(:fetch_availabilities) { Result.new(availabilities) }

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
  end
end
