require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Legacy::Metadata do
  include Support::Factories

  let(:supplier) { create_supplier(name: 'KigoLegacy') }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let(:property_content_diff) { Hash['DIFF_ID' => 'abc', 'PROP_ID' => [1, 2]] }

  subject { described_class.new(supplier, current_run_args) }
  let(:current_run_args) { Concierge::SafeAccessHash.new({}) }

  context 'first run with empty diff id' do
    before do
      expect_any_instance_of(Kigo::Importer).to receive(:fetch_property_content_diff).with(nil) {
        Result.new(property_content_diff)
      }
      expect(subject).to receive(:update_property).exactly(2).times
      expect(subject).to receive(:announce_all_errors).exactly(1).times
    end

    it 'returns a result with hash for next run' do
      result = subject.perform
      expect(result).to be_success
      expect(result.value).to eq({ property_content_diff_id: "abc" })
    end
  end

  context 'subsequent run with exisiting property_content_diff_id' do
    let(:current_run_args) { Concierge::SafeAccessHash.new({property_content_diff_id: "xyz"}) }
    before do
      expect_any_instance_of(Kigo::Importer).to receive(:fetch_property_content_diff).with("xyz") {
        Result.new(property_content_diff)
      }
      expect(subject).to receive(:update_property).exactly(2).times
      expect(subject).to receive(:announce_all_errors).exactly(1).times
    end
    it 'returns a result with hash for next run' do
      result = subject.perform
      expect(result).to be_success
      expect(result.value).to eq({ property_content_diff_id: "abc" })
    end
  end

  describe '#announce_all_errors' do
    context 'when there are errors returned from property updates' do
      let(:update_results) { [
        Result.new(true),
        Result.error(:no_host),
        Result.error(:unsupported_property),
        Result.error(:connection_timeout),
        Result.error(:http_status_429),
        Result.new(true)
      ]}
      it 'creates an external error for each' do
        expect {
          subject.send(:announce_all_errors, update_results)
        }.to change { ExternalErrorRepository.count }.by 4
      end
    end
  end
end
