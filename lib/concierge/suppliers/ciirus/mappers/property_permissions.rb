module Ciirus
  module Mappers
    class PropertyPermissions
      # Maps hash representation of Ciirus API GetPropertyPermissions response
      # to +Ciirus::Entities::PropertyPermissions+
      def build(hash)
        permissions_hash = hash.get('get_property_permissions_response.get_property_permissions_result')
        attrs = {}
        copy_property_id!(permissions_hash, attrs)
        copy_mc_enable_property!(permissions_hash, attrs)
        copy_agent_enable_property!(permissions_hash, attrs)
        copy_agent_user_id!(permissions_hash, attrs)
        copy_mc_user_id!(permissions_hash, attrs)
        copy_native_property!(permissions_hash, attrs)
        copy_calendar_sync_property!(permissions_hash, attrs)
        copy_aoa_property!(permissions_hash, attrs)
        copy_time_share!(permissions_hash, attrs)
        copy_online_booking_allowed!(permissions_hash, attrs)
        fill_deleted!(permissions_hash, attrs)

        Entities::PropertyPermissions.new(attrs)
      end

      private

      def fill_deleted!(hash, attrs)
        attrs[:deleted] = (hash[:error_msg] == Ciirus::Commands::PropertyPermissionsFetcher::PROPERTY_DELETED_MESSAGE)
      end

      def copy_property_id!(hash, attrs)
        attrs[:property_id] = hash[:property_id]
      end

      def copy_mc_enable_property!(hash, attrs)
        attrs[:mc_enable_property] = hash[:mc_enable_property]
      end

      def copy_agent_enable_property!(hash, attrs)
        attrs[:agent_enable_property] = hash[:agent_enable_property]
      end

      def copy_agent_user_id!(hash, attrs)
        attrs[:agent_user_id] = hash[:agent_user_id]
      end

      def copy_mc_user_id!(hash, attrs)
        attrs[:mc_user_id] = hash[:mc_user_id]
      end

      def copy_native_property!(hash, attrs)
        attrs[:native_property] = hash[:native_property]
      end

      def copy_calendar_sync_property!(hash, attrs)
        attrs[:calendar_sync_property] = hash[:calendar_sync_property]
      end

      def copy_aoa_property!(hash, attrs)
        attrs[:aoa_property] = hash[:aoa_property]
      end

      def copy_time_share!(hash, attrs)
        attrs[:time_share] = hash[:time_share]
      end

      def copy_online_booking_allowed!(hash, attrs)
        attrs[:online_booking_allowed] = hash[:online_booking_allowed]
      end
    end
  end
end
