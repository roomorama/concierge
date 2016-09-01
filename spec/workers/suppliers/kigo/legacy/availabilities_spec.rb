require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Legacy::Availabilities do
  include Support::Fixtures
  include Support::Factories

  let(:args) {
    {
      prices_diff_id:       '123',
      reservations_diff_id: '321'
    }
  }
  let(:supplier) { create_supplier(name: 'Kigo') }
  let!(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }

  subject { described_class.new(supplier, args) }

  describe '#perform' do
    let(:prices_diff) { Hash['DIFF_ID' => 'abc', 'PROP_ID' => [1, 2]] }
    let(:reservations_diff) { JSON.parse(read_fixture('kigo_legacy/reservations_diff.json')) }

    it 'announces external error' do
      expect_any_instance_of(Kigo::Importer).
        to receive(:fetch_prices_diff).with(args[:prices_diff_id]) { Result.error(:connection_timeout) }

      expect(subject.perform).to be_nil

      external_error = ExternalErrorRepository.last

      expect(external_error.supplier).to eq 'Kigo'
      expect(external_error.code).to eq 'connection_timeout'
    end

    it 'perform calendar worker call' do
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_prices_diff) { Result.new(prices_diff) }
      allow_any_instance_of(Kigo::Importer).to receive(:fetch_reservations_diff) { Result.new(reservations_diff) }

      expect(subject).to receive(:update_calendar).with(host, [1, 2, 194962, 194966])

      result = subject.perform

      expect(result).to be_success
      expect(result.value).to eq({ prices_diff_id: 'abc', reservations_diff_id: 'vdbfo' })
    end
  end

end