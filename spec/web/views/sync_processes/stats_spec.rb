require "spec_helper"
require_relative '../../../../apps/web/views/sync_processes/stats'

RSpec.describe Web::Views::SyncProcesses::Stats do
  include Support::Factories

  let(:metadata)       { SyncProcessRepository.all.first }
  let(:exposures)      { Hash[sync_process: metadata] }
  let(:template)       { Hanami::View::Template.new('apps/web/templates/sync_processes/stats.html.erb') }
  let(:view)           { described_class.new(template, exposures) }
  let(:rendered)       { view.render }


  let(:sanitized) { rendered.gsub("\n", "").gsub(/\s\s+/, " ") }

  before do
    metadata_supplier = create_supplier(name: "Metadata Supplier")
    metadata_host     = create_host(supplier_id: metadata_supplier.id, username: "metadata-host")

    create_sync_process(type: "metadata", successful: false, host_id: metadata_host.id, stats: {
      properties_created: 2,
      properties_updated: 10,
      properties_deleted: 1,
      properties_skipped: [
        {
          reason: 'Error 1',
          ids: ['314', '345']
        }
      ]
    })
  end

  it "includes information about metadata sync processes" do
    expect(sanitized).to include %(: 2)  # properties created
    expect(sanitized).to include %(: 10) # properties updated
    expect(sanitized).to include %(: 1)  # properties deleted
    expect(sanitized).to include %(314)  # skipped property
  end
end
