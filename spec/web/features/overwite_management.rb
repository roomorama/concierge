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

  it 'overwrites index is navigatable from home page' do
    visit '/'
    click_on supplier.id
    within "#host-row-#{host.id}" do
      click_on "1 overwrite"
    end

    expect(page.body).to have_content "Property attribute enforcements for #{host.username}"
    expect(page.body).to have_content "{\"cancellation_policy\":\"flexible\"}"
    click_on "Create New"
    expect(page.current_path).to eq "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites/new"
  end

  describe "creating new" do
    it 'is successful' do
      expect {
        visit "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites/new"
        fill_in "overwrite[data_json]", with: '{"cancellation_policy":"flexible"}'
        fill_in "overwrite[property_identifier]", with: 'asdf'
        click_on "Submit"
      }.to change { OverwriteRepository.count }.by 1
    expect(page.body).to have_content "Successfully created"
    expect(page.current_path).to eq "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites"
    expect(OverwriteRepository.last.property_identifier).to eq 'asdf'
    end

    it 'shows error message if data is not of valid json format' do
      expect_any_instance_of(Concierge::Flows::OverwriteManagement).to receive(:validate) { Result.error(:invalid_data, "Some validation message") }
      expect {
        visit "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites/new"
        fill_in "overwrite[data_json]", with: '{"cancellation_policy": invalid_cancellation}'
        click_on "Submit"
        expect(page.body).to have_content "Some validation message"
      }.to_not change { OverwriteRepository.count }
    end
  end

  describe "editing" do
    it "is successful" do
      visit "/suppliers/#{supplier.id}/hosts/#{host.id}/overwrites"
      within "#overwrite-row-#{overwrite.id}" do
        click_on "Edit"
      end
      expect(page.body).to have_content overwrite.data.to_h.to_json
      fill_in "overwrite[data_json]", with: '{"cancellation_policy":"no_refund"}'
      click_on "Submit"
      expect(page.body).to have_content "Successfully updated"
      expect(OverwriteRepository.last.data.get("cancellation_policy")).to eq "no_refund"
    end
  end
end
