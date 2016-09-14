require 'spec_helper'

RSpec.describe Ciirus::Mappers::PropertyPermissions do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_property_permissions_response: {
            get_property_permissions_result: {
              property_id: '33680',
              mc_enable_property: true,
              agent_enable_property: true,
              agent_user_id: '38716',
              mc_user_id: '11006',
              native_property: false,
              calendar_sync_property: false,
              aoa_property: false,
              time_share: false,
              online_booking_allowed: true
            },
            :@xmlns=>"http://xml.ciirus.com/"
          }
        }
      )
    end

    let(:deleted_result_hash) do
      Concierge::SafeAccessHash.new(
        {
          get_property_permissions_response: {
            get_property_permissions_result: {
              error_msg: 'Error (1012-CS) This property has been deleted. Please contact the inventory supplier.',
            },
            :@xmlns=>"http://xml.ciirus.com/"
          }
        }
      )
    end

    subject { described_class.new }

    it 'returns mapped property permissions entity' do
      permissions = subject.build(result_hash)
      expect(permissions).to be_a(Ciirus::Entities::PropertyPermissions)
      expect(permissions.property_id).to eq('33680')
      expect(permissions.mc_enable_property).to be_truthy
      expect(permissions.agent_enable_property).to be_truthy
      expect(permissions.agent_user_id).to eq('38716')
      expect(permissions.mc_user_id).to eq('11006')
      expect(permissions.native_property).to be_falsey
      expect(permissions.calendar_sync_property).to be_falsey
      expect(permissions.aoa_property).to be_falsey
      expect(permissions.time_share).to be_falsey
      expect(permissions.online_booking_allowed).to be_truthy
      expect(permissions.deleted).to be_falsey
    end

    it 'returns deleted property permissions if appropriate error message' do
      permissions = subject.build(deleted_result_hash)
      expect(permissions).to be_a(Ciirus::Entities::PropertyPermissions)
      expect(permissions.deleted).to be_truthy
    end
  end

end
