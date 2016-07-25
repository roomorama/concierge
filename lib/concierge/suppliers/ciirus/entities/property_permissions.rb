module Ciirus
  module Entities
    class PropertyPermissions
      attr_reader :property_id, :mc_enable_property, :agent_enable_property, :agent_user_id, :mc_user_id,
                  :native_property, :calendar_sync_property, :aoa_property, :time_share,
                  :online_booking_allowed

      def initialize(attrs = {})
        @property_id            = attrs[:property_id]
        @mc_enable_property     = attrs[:mc_enable_property]
        @agent_enable_property  = attrs[:agent_enable_property]
        @agent_user_id          = attrs[:agent_user_id]
        @mc_user_id             = attrs[:mc_user_id]
        @native_property        = attrs[:native_property]
        @calendar_sync_property = attrs[:calendar_sync_property]
        @aoa_property           = attrs[:aoa_property]
        @time_share             = attrs[:time_share]
        @online_booking_allowed = attrs[:online_booking_allowed]
      end
    end
  end
end