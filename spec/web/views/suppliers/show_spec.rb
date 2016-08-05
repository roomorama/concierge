require "spec_helper"

RSpec.describe Web::Views::Suppliers::Show do
  include Support::Factories

  let(:supplier)  { create_supplier(name: "Supplier Y") }
  let(:hosts)     { HostRepository.from_supplier(supplier) }
  let(:exposures) { Hash[supplier: supplier, hosts: hosts] }
  let(:template)  { Hanami::View::Template.new('apps/web/templates/suppliers/show.html.erb') }
  let(:view)      { described_class.new(template, exposures) }
  let(:rendered)  { view.render }

  let(:sanitized) { rendered.gsub("\n", "").gsub(/\s\s+/, " ") }

  before do
    2.times { |n|
      create_host(supplier_id: supplier.id, identifier: "host#{n}", access_token: "token#{n}")
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

    expect(sanitized).to include %(<td><code>token...</code></td>)
  end

  it "presents the synchronisation frequency for each supplier worker" do
    # use a supplier existent in the config/suppliers.yml file
    supplier.name = "AtLeisure"
    SupplierRepository.update(supplier)

    expect(sanitized).to include %(<em>Metadata:</em> every day)
    expect(sanitized).to include %(<em>Calendar:</em> every 5 hours)
  end

end
