require 'spec_helper'

RSpec.describe Workers::Suppliers::Kigo::Metadata do
  include Support::Factories

  let(:supplier) { create_supplier(name: 'Kigo') }
  let(:host) { create_host(supplier_id: supplier.id, identifier: '14908') }
  let(:property_content_diff) { Hash['DIFF_ID' => 'abc', 'PROP_ID' => [1, 2]] }

  subject { described_class.new(supplier, current_run_args) }

  context 'first run with empty diff id' do
    let(:current_run_args) { Concierge::SafeAccessHash.new({}) }
    before do
      expect_any_instance_of(Kigo::Importer).to receive(:fetch_property_content_diff).with(nil) {
        Result.new(property_content_diff)
      }
      expect(subject).to receive(:update_property).exactly(2).times
    end

    it do
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
    end
    it do
      result = subject.perform
      expect(result).to be_success
      expect(result.value).to eq({ property_content_diff_id: "abc" })
    end
  end
end
