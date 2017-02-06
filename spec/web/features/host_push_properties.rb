require 'spec_helper'
require 'feature_helper'

RSpec.describe 'host push properties to Roomorama again', type: :feature do
  include Support::Factories
  include Hanami::Helpers

  let!(:supplier) { create_supplier }
  let!(:host)     { create_host(supplier_id: supplier.id) }
  let!(:properties) { 3.times.collect { |i| create_property(host_id: host.id, identifier: i) } }

  before { page.driver.browser.authorize 'admin', 'admin' }

  it 'lets admin push selected properties of a host' do
    expect_any_instance_of(Concierge::Flows::PropertiesPushJobEnqueue).to receive(:call) do |flow|
      expect(flow.element.data.count).to eq 2
    end

    visit "suppliers/#{supplier.id}/hosts/#{host.id}"
    click_on "Push Properties"
    expect(page.body).to have_content properties.sample.title

    # checks 2 properties
    check "property-#{properties.sample.id}"
    check "property-#{properties.sample.id}"

    click_on "Push"

    expect(page.current_path).to eq "/suppliers/#{supplier.id}/hosts/#{host.id}"
    expect(page.body).to have_content "Properties push process queued"
  end

  it 'alerts admin if no properties was queued' do
    visit "suppliers/#{supplier.id}/hosts/#{host.id}"
    click_on "Push Properties"
    expect(page.body).to have_content properties.sample.title

    # doesn't check any checkboxes

    click_on "Push"

    expect(page.current_path).to eq "/suppliers/#{supplier.id}/hosts/#{host.id}"
    expect(page.body).to have_content "No properties queued."
  end
end

