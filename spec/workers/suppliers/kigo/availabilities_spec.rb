require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Availabilities do
  include Support::Fixtures
  include Support::Factories

  let(:args) {
    {
      prices_diff_id:         '123',
      availabilities_diff_id: '321'
    }
  }
  let(:supplier) { create_supplier(name: 'Kigo') }
  let!(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }

  subject { described_class.new(supplier, args) }

  describe '#perform' do
    let(:prices_diff) { Hash['DIFF_ID' => 'abc', 'PROP_ID' => [1, 2]] }
    let(:availabilities_diff) { Hash['DIFF_ID' => 'xyz', 'PROP_ID' => [2, 3]] }

    context 'there are events from previous syncs in current context' do
      before do
        Concierge.context = Concierge::Context.new(type: "batch")

        sync_process = Concierge::Context::SyncProcess.new(
          worker:     "availabilities",
          host_id:    "UNRELATED_HOST",
          identifier: "UNRELATED_PROPERTY"
        )
        Concierge.context.augment(sync_process)
        allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices_diff) { Result.error(:connection_timeout) }
      end

      it 'announces an error without any unrelated context' do
        subject.perform
        error = ExternalErrorRepository.last
        expect(error.context.get("events").to_s).to_not include("UNRELATED_PROPERTY")
      end
    end

    it 'announces external error' do
      expect_any_instance_of(Kigo::Importer).
        to receive(:fetch_prices_diff).with(args[:prices_diff_id]) { Result.error(:connection_timeout) }

      result = subject.perform

      expect(result).to be_success
      expect(result.value).to eq args

      external_error = ExternalErrorRepository.last

      expect(external_error.supplier).to eq 'Kigo'
      expect(external_error.code).to eq 'connection_timeout'
    end

    it 'perform calendar worker call' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices_diff) { Result.new(prices_diff) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_availabilities_diff) { Result.new(availabilities_diff) }

      expect(subject).to receive(:update_calendar).with(host, [1, 2, 3])

      result = subject.perform

      expect(result).to be_success
      expect(result.value).to eq({ prices_diff_id: 'abc', availabilities_diff_id: 'xyz' })
    end
  end

end