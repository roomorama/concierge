require "spec_helper"

RSpec.describe Workers::Suppliers::Audit do
  include Support::Factories
  include Support::Fixtures

  let(:host) { create_host }
  let(:worker) { described_class.new(host) }
  let(:fetch_properties_json) { JSON.parse(read_fixture('audit/properties.json')) }
  let(:credentials) { Hash.new }

  def synchronisation_counters
    [:created, :updated, :deleted].inject({}) do |sum,k|
      sum.merge(k => @counters.send(k))
    end
  end

  before do
    # do NOT make API calls during tests
    allow_any_instance_of(Workers::Synchronisation).to receive(:run_operation).and_return(nil)

    # keep track of counters
    @counters = Workers::Synchronisation::PropertyCounters.new(0, 0, 0)
    allow_any_instance_of(Workers::Synchronisation).to receive(:save_sync_process) do |instance, *args|
      @counters = instance.counters
    end
  end

  describe "perform" do

    before do
      allow_any_instance_of(Audit::Importer).to receive(:fetch_properties) do
        Result.new(fetch_properties_json['result'])
      end
    end

    subject { proc { worker.perform } }

    context "fetched new property" do
      it { is_expected.to change { synchronisation_counters }.to eq(created: 1, updated: 0, deleted: 0) }
    end

    context "fetched existing property" do
      before do
        fetch_properties_json['result'].each do |json|
          result = Audit::Importer.new(credentials).json_to_property(json)
          roomorama_property = result.value
          # See Workers::Router#dispatch
          # enqueues a diff operation if there is a property with the same identifier for the same host
          data = roomorama_property.to_h.merge!(title: "Different title")
          create_property(host_id: host.id, identifier: roomorama_property.identifier, data: data)
        end
      end

      it { is_expected.to change { synchronisation_counters }.to eq(created: 0, updated: 1, deleted: 0) }
    end

    context "error when importing json_to_property" do
      before do
        allow_any_instance_of(Audit::Importer).to receive(:json_to_property) do
          Result.error(:missing_required_data, { 'foo' => 'bar'} )
        end
      end

      it { is_expected.not_to change { synchronisation_counters } }
    end

    context "error when fetching" do
      before do
        allow_any_instance_of(Audit::Importer).to receive(:fetch_properties) do
          Result.error(:network_failure)
        end
      end

      it { is_expected.not_to change { synchronisation_counters } }
    end
  end
end
