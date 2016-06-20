require 'spec_helper'

RSpec.describe Workers::Suppliers::AtLeisure do
  include Support::Fixtures

  let(:properties_list) { JSON.parse(read_fixture('atleisure/properties_list.json')) }
  let(:success_result) { Result.new(properties_list) }
  let(:host) { Host.new(identifier: 'superman', username: 'Clark') }

  subject { described_class.new(host) }

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { Result.error(:json_rpc_response_has_errors) }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq 'AtLeisure'
    expect(error.code).to eq 'json_rpc_response_has_errors'
  end

  context 'fetching data' do
    before do
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { success_result }
      allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_data) { Result.error(:invalid_json_rpc_response) }
    end

    it 'announces an error if fetching data fails' do
      subject.perform

      error = ExternalErrorRepository.last

      expect(error.operation).to eq 'sync'
      expect(error.supplier).to eq 'AtLeisure'
      expect(error.code).to eq 'invalid_json_rpc_response'
    end

    it 'doesnt finalize synchronisation with external error' do
      expect(Roomorama::Client::Operations).to_not receive(:disable)
      subject.perform
    end
  end

  it 'finalizes synchronisation if success' do
    allow_any_instance_of(AtLeisure::Importer).to receive(:fetch_properties) { success_result }
    allow(subject).to receive(:fetch_data_and_process) { [] }

    expect(subject.synchronisation).to receive(:finish!)
    subject.perform
  end
end