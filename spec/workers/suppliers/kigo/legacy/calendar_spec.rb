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

  describe '#can_proceed' do
    context "when host has no properties" do
      it "should be true" do
        host_with_no_properties = create_host(suplpier_id: supplier.id)
        calendar = described_class.new(host_with_no_properties, [identifier])
        expect(calendar.send(:can_proceed?)).to eq true
      end
    end

    context  "when host has properites" do
      it "should call Kigo::HostCheck with all property ids" do
        expect_any_instance_of(Kigo::HostCheck).to receive(:active?) do |host_check|
          expect(host_check.property_ids).to be_a Array
          expect(host_check.property_ids).to_not be_empty
          Result.new(true)
        end
        expect(subject.send(:can_proceed?)).to eq true
      end
    end
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

    context 'deactivated host' do

      it 'stops process with deactivated host' do
        allow_any_instance_of(Kigo::HostCheck).to receive(:active?) { Result.new(false) }

        expect { subject.perform }.not_to change { SyncProcessRepository.count }
      end

      it 'stops process with external error' do
        allow_any_instance_of(Kigo::HostCheck).to receive(:active?) { Result.error(:connection_timeout) }

        expect { subject.perform }.not_to change { SyncProcessRepository.count }
      end

    end

    context 'active host' do

      before { allow_any_instance_of(Kigo::HostCheck).to receive(:active?) { Result.new(true) } }

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
        expect(stats[:available_records]).to eq 359
        expect(stats[:unavailable_records]).to eq days_count + 1
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
end
