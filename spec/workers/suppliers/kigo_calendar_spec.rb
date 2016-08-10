require 'spec_helper'

RSpec.describe Workers::Suppliers::KigoCalendar do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let(:property) { create_property(host_id: host.id) }

  subject { described_class.new(host) }

  describe '#perform' do
    it 'works :)' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect { subject.perform }.to change {
        SyncProcessRepository.count
      }.by(1)

      sync_process = SyncProcessRepository.last

      expect(sync_process.successful).to eq true
      expect(sync_process.host_id).to eq host.id
      expect(sync_process.type).to eq 'availabilities'
    end

  end

end