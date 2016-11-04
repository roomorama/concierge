require 'spec_helper'

RSpec.describe Workers::Suppliers::THH::Metadata do
  include Support::Fixtures
  include Support::Factories

  let(:supplier) { create_supplier(name: THH::Client::SUPPLIER_NAME) }
  let(:host) { create_host(supplier_id: supplier.id) }

  let(:today) { Date.new(2016, 12, 10) }

  before do
    allow(Date).to receive(:today).and_return(today)
  end

  subject { described_class.new(host) }

  context 'there are events from previous syncs in current context' do
    before do
      Concierge.context = Concierge::Context.new(type: "batch")

      sync_process = Concierge::Context::SyncProcess.new(
        worker:     "metadata",
        host_id:    "UNRELATED_HOST",
        identifier: "UNRELATED_PROPERTY"
      )
      Concierge.context.augment(sync_process)
      allow_any_instance_of(THH::Importer).to receive(:fetch_properties) { Result.error(:error) }
    end

    it 'announces an error without any unrelated context' do
      subject.perform
      error = ExternalErrorRepository.last
      expect(error.context.get("events").to_s).to_not include("UNRELATED_PROPERTY")
    end
  end

  it 'announces an error if fetching properties fails' do
    allow_any_instance_of(THH::Importer).to receive(:fetch_properties) { Result.error(:error, 'Some error') }

    subject.perform

    error = ExternalErrorRepository.last

    expect(error.operation).to eq 'sync'
    expect(error.supplier).to eq THH::Client::SUPPLIER_NAME
    expect(error.code).to eq 'error'
    expect(error.description).to eq 'Some error'
  end

  it 'saves sync process even if error occures before start call' do
    allow_any_instance_of(THH::Importer).to receive(:fetch_properties) { Result.error(:error, 'Some error') }

    expect(subject.synchronisation).to receive(:skip_purge!).once.and_call_original
    subject.perform

    sync = SyncProcessRepository.last

    expect(sync).not_to be_nil
    expect(sync.successful).to be false
    expect(sync.host_id).to eq(host.id)
  end

  context 'success' do
    let(:properties) { read_properties('thh/properties_response.xml') }

    before do
      allow_any_instance_of(THH::Importer).to receive(:fetch_properties) { Result.new(properties) }
    end

    it 'finalizes synchronisation' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }

      expect(subject.synchronisation).to receive(:finish!)
      subject.perform
    end

    it 'doesnt create property with unsuccessful publishing' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.error('fail') }
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'does not create invalid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      allow_any_instance_of(THH::Validators::PropertyValidator).to receive(:valid?) { false }

      expect(subject.synchronisation).to receive(:skip_property).once.and_call_original
      expect {
        subject.perform
      }.to_not change { PropertyRepository.count }
    end

    it 'creates valid properties in database' do
      allow_any_instance_of(Roomorama::Client).to receive(:perform) { Result.new('success') }
      expect {
        subject.perform
      }.to change { PropertyRepository.count }.by(1)
    end
  end

  def read_properties(name)
    parser = Nori.new
    response = parser.parse(read_fixture(name))['response']
    Array(Concierge::SafeAccessHash.new(response['property']))
  end
end
