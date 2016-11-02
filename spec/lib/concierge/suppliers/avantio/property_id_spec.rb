require 'spec_helper'

RSpec.describe Avantio::PropertyId do

  let(:accommodation_code) { '79499' }
  let(:user_code) { '29' }
  let(:login_ga) { 'carlademo' }
  let(:property_id) { '79499|29|carlademo' }

  it 'allows to create property id from avantio ids' do
    p_id = described_class.from_avantio_ids(
      accommodation_code, user_code, login_ga
    )

    expect(p_id.property_id).to eq(property_id)
  end

  it 'allows to create property id from roomorama property id' do
    p_id = described_class.from_roomorama_property_id(property_id)

    expect(p_id.property_id).to eq(property_id)
    expect(p_id.accommodation_code).to eq(accommodation_code)
    expect(p_id.user_code).to eq(user_code)
    expect(p_id.login_ga).to eq(login_ga)
  end
end