require 'spec_helper'

RSpec.describe Workers::Suppliers::JTB::Metadata do
  include Support::Factories

  let(:supplier) { create_supplier(name: Ciirus::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  subject { described_class.new(host) }

  it 'announces an error if db actualization fails' do
    allow_any_instance_of(JTB::Sync::Actualizer).to receive(:actualize) { Result.error(:error) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq JTB::Client::SUPPLIER_NAME
    expect(error.code).to eq 'error'
  end
end