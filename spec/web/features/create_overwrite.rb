require 'spec_helper'
require 'feature_helper'

RSpec.describe 'managing overwrites for a host', type: :feature do
  include Support::Factories

  let!(:supplier)  { create_supplier }
  let!(:host)      { create_host(supplier_id: supplier.id) }
  let!(:overwrite) { create_overwrite(
    host_id: host.id,
    data:    { "cancellation_policy" => "flexible" }
  ) }

  before { page.driver.browser.authorize 'admin', 'admin' }

  it 'navigatable from home page' do
    visit '/'
    click_on supplier.id
    within "#host-row-#{host.id}" do
      click_on "Overwrites"
    end

    expect(page.body).to have_content "Property attribute enforcements for #{host.username}"
    expect(page.body).to have_content '{"cancellation_policy":"flexible"}'
    expect(page.body).to have_content 'Create New'
  end

  describe "creating new" do
    it 'is successful for empty property_identifier' do
      expect {
        visit "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites/new"
        fill_in "overwrite[data]", with: '{"cancellation_policy":"flexible"}'
        click_on "Submit"
      }.to change { OverwriteRepository.count }.by 1
    end
  end
end
