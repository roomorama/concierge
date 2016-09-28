require "spec_helper"

RSpec.describe Web::Views::Suppliers::Show do
  include Support::Factories

  let(:supplier)  { create_supplier(name: "Supplier Y") }
  let(:hosts)     { HostRepository.from_supplier(supplier) }

  # Hanami has a weird issue when rendering partials on the test environment when
  # the views are initialized as above (as suggested on the official guides). For some
  # reason, the format is not recognised, and it fails to render with a cryptic error
  # message.
  #
  # Hardcoding the format to +html+ for the rendered view allows the specs to pass.
  # TODO get rid of this when upgrading Hanami, hopefully it will have been fixed.
  let(:exposures) { Hash[supplier: supplier, hosts: hosts, format: :html] }

  let(:template)  { Hanami::View::Template.new('apps/web/templates/suppliers/show.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  let(:sanitized) { rendered.gsub("\n", "").gsub(/\s\s+/, " ") }

  before do
    2.times { |n|
      create_host(supplier_id: supplier.id, fee_percentage: (n + 2).to_f, identifier: "host#{n}", access_token: "token#{n}")
    }
  end

  it "includes the number of integrated hosts and properties" do
    host = HostRepository.from_supplier(supplier).first
    5.times { |n| create_property(host_id: host.id, identifier: "prop#{n}") }

    expect(sanitized).to include %(<h2 class="content-subhead">Supplier Y</h2>)
    expect(sanitized).to include %(Supplier Y has <em>2</em> integrated hosts) +
      %( and currently provides <em>5</em> properties to Roomorama)
  end

  it "renders a list of hosts for the supplier" do
    expect(sanitized).to include %(<td><code>host0</code></td>)
    expect(sanitized).to include %(<td><code>host1</code></td>)
    expect(sanitized).to include %(<td>2.0%</td>)
    expect(sanitized).to include %(<td>3.0%</td>)

    expect(sanitized).to include %(<td><code>token...</code></td>)
  end

  it "presents the synchronisation frequency for each supplier worker" do
    # use a supplier existent in the config/suppliers.yml file
    supplier.name = "AtLeisure"
    SupplierRepository.update(supplier)

    expect(sanitized).to include %(<em>Metadata:</em> every day)
    expect(sanitized).to include %(<em>Availabilities:</em> every 5 hours)
  end

  it "presents the status of workers for the hosts of the supplier" do
    create_background_worker(
      type:        "metadata",
      host_id:     hosts.first.id,
      status:      "idle",
      next_run_at: nil
    )
    create_background_worker(
      type:        "availabilities",
      host_id:     hosts.first.id,
      status:      "running",
      next_run_at: Time.new(2016, 5, 22, 12, 32)
    )

    # no aggregated synchronisation for this supplier
    expect(sanitized).not_to include %(<h4>Aggregated synchrnonisation</h4>)

    expect(sanitized).to include %(<td>metadata</td>)
    expect(sanitized).to include %(<td>availabilities</td>)

    expect(sanitized).to include %(<button class="secondary-button pure-button">idle</button>)
    expect(sanitized).to include %(<button class="success-button pure-button">running</button>)

    expect(sanitized).to include %(<td>Soon (in at most 10 minutes)</td>)
    expect(sanitized).to include %(<td>May 22, 2016 at 12:32</td>)
  end
end
