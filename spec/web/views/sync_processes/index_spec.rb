require "spec_helper"

RSpec.describe Web::Views::SyncProcesses::Index do
  include Support::Factories

  let(:metadata)       { SyncProcessRepository.of_type("metadata") }
  let(:availabilities) { SyncProcessRepository.of_type("availabilities") }
  let(:exposures)      { Hash[metadata_processes: metadata, availabilities_processes: availabilities] }
  let(:template)       { Hanami::View::Template.new('apps/web/templates/sync_processes/index.html.erb') }
  let(:view)           { described_class.new(template, exposures) }
  let(:rendered)       { view.render }

  let(:sanitized) { rendered.gsub("\n", "").gsub(/\s\s+/, " ") }

  before do
    metadata_supplier = create_supplier(name: "Metadata Supplier")
    metadata_host     = create_host(supplier_id: metadata_supplier.id, username: "metadata-host")

    availabilities_supplier = create_supplier(name: "Availabilities Supplier")
    availabilities_host     = create_host(supplier_id: availabilities_supplier.id, username: "availabilities-host")

    create_sync_process(type: "metadata", host_id: metadata_host.id, stats: {
      properties_created: 2,
      properties_updated: 10,
      properties_deleted: 1
    })

    create_sync_process(type: "availabilities", host_id: availabilities_host.id, stats: {
      properties_processed: 20,
      available_records: 103,
      unavailable_records: 48
    })
  end

  it "includes information about metadata sync processes" do
    expect(sanitized).to include %(<td>Metadata Supplier</td>)
    expect(sanitized).to include %(<td>metadata-host</td>)
    expect(sanitized).to include %(<td>2</td>)  # properties created
    expect(sanitized).to include %(<td>10</td>) # properties updated
    expect(sanitized).to include %(<td>1</td>)  # properties deleted
  end

  it "includes information about availabilities sync processes" do
    expect(sanitized).to include %(<td>Availabilities Supplier</td>)
    expect(sanitized).to include %(<td>availabilities-host</td>)
    expect(sanitized).to include %(<td>20</td>)  # properties processed
    expect(sanitized).to include %(<td>103</td>) # available records
    expect(sanitized).to include %(<td>48</td>)  # unavailable records
  end
end
