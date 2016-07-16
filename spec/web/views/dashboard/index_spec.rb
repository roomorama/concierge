require "spec_helper"

RSpec.describe Web::Views::Dashboard::Index do
  include Support::HTTPStubbing
  include Support::Factories

  let(:status_check) { Web::Support::StatusCheck.new }
  let(:exposures)    { Hash[concierge: status_check, suppliers: SupplierRepository.all.to_a] }
  let(:template)     { Hanami::View::Template.new('apps/web/templates/dashboard/index.html.erb') }
  let(:view)         { described_class.new(template, exposures) }
  let(:rendered)     { view.render }

  let(:application_json) { { "Content-Type" => "application/json" } }
  let(:successful_response) {
    {
      "status"  => "ok",
      "time"    => "2016-05-14 05:58:56 UTC",
      "version" => "0.1.4"
    }.to_json
  }

  def concierge_responds_with
    stub_call(:get, "https://concierge.roomorama.com/_ping") { yield }
  end

  it "indicates that Concierge is alive" do
    concierge_responds_with { [200, application_json, successful_response] }
    expect(rendered).to include %(<span class="concierge-success">Up</span>)
  end

  it "indicates that Concierge is unreachable" do
    concierge_responds_with { raise Faraday::TimeoutError }
    expect(rendered).to include %(<span class="concierge-failure">Down</span>)
  end

  it "indicates that Concierge is healthy" do
    concierge_responds_with { [200, application_json, successful_response] }
    expect(rendered).to include %(<span class="concierge-success">Yes</span>)
  end

  it "indicates that Concierge is not healthy" do
    concierge_responds_with { [500, application_json, successful_response] }
    expect(rendered).to include %(<span class="concierge-failure">No</span>)
  end

  it "shows Concierge running version" do
    concierge_responds_with { [200, application_json, successful_response] }
    expect(rendered).to include %(<strong>Version:</strong> 0.1.4)
  end

  it "shows the error message in case Concierge is not healthy" do
    concierge_responds_with { [500, application_json, "Something went wrong"] }
    expect(rendered).to include %(<strong>Error:</strong> <code>http_status_500</code>)
  end

  it "includes the total number of reservations performed by Concierge" do
    2.times { create_reservation }
    expect(rendered).to include %(A total of 2 reservations have been created on Concierge.)
  end

  it "includes all suppliers, as well as number of hosts and properties" do
    supplier = create_supplier(name: "Supplier X")
    host1 = create_host(identifier: "host1", supplier_id: supplier.id)
    host2 = create_host(identifier: "host2", supplier_id: supplier.id)

    create_property(host_id: host1.id)

    expect(rendered).to include %(<td>Supplier X</td>) # supplier name
    expect(rendered).to include %(<td>2</td>)          # hosts
    expect(rendered).to include %(<td>1</td>)          # properties
  end
end
