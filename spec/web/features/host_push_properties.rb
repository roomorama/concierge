require 'spec_helper'
require 'feature_helper'

RSpec.describe 'host push properties to Roomorama again', type: :feature do
  include Support::Factories
  include Hanami::Helpers

  let!(:supplier) { create_supplier }
  let!(:host)     { create_host(supplier_id: supplier.id) }

  before { page.driver.browser.authorize 'admin', 'admin' }

  it 'lets admin push all properties of a host' do
    expect_any_instance_of(Concierge::Flows::PropertyPush).to receive :call

    visit "suppliers/#{supplier.id}/hosts/#{host.id}"
    click_on "Push Properties"
    click_on "Push"

    expect(page.current_path).to eq "/suppliers/#{supplier.id}/hosts/#{host.id}"
  end
end

