module Ciirus
  module Commands
    #  +Ciirus::Commands::PropertyPermissionsFetcher+
    #
    # This class is responsible for fetching property permissions and relationship
    # settings from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::PropertyPermissionsFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +PropertyPermissions+.
    class PropertyPermissionsFetcher < BaseCommand

      OPERATION_NAME = :get_property_permissions

      PROPERTY_DELETED_MESSAGE = 'Error (1012-CS) This property has been deleted. Please contact the inventory supplier. '
      MC_PROPERTY_DISABLED_MESSAGE = 'Error (8000) The MC may have disabled the property from the feed. The MC user for '\
        'this property has not enabled this property for your feed, but you have accepted this property'\
        ' in the SuperSites area of the CiiRUS windows application. '
      MC_DISABLED_CLONE_PROPERTY_MESSAGE = 'Error (15000) The MC may have disabled the clone property from the feed. The MC '\
        'user for this property has not enabled this property for your feed, but you have accepted this property in '\
        'the SuperSites area of the CiiRUS windows application. '
      IGNORABLE_ERROR_MESSAGES = [PROPERTY_DELETED_MESSAGE, MC_PROPERTY_DISABLED_MESSAGE, MC_DISABLED_CLONE_PROPERTY_MESSAGE]


      def call(property_id)
        message = xml_builder.property_permissions(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            property_permissions = mapper.build(result_hash)
            Result.new(property_permissions)
          else
            error_result(result_hash)
          end
        else
          result
        end
      end

      protected

      def operation_name
        OPERATION_NAME
      end

      private

      def mapper
        @mapper ||= Ciirus::Mappers::PropertyPermissions.new
      end

      def valid_result?(result_hash)
        error_msg = result_hash.get('get_property_permissions_response.get_property_permissions_result.error_msg')
        # Special case for property deleted message. Instead of response mismatch augment PropertyPermissions.deleted
        # field will contain true/false value for further business logic.
        error_msg.nil? || error_msg.empty? || IGNORABLE_ERROR_MESSAGES.include?(error_msg)
      end

      def error_result(result_hash)
        error_msg = result_hash.get('get_property_permissions_response.get_property_permissions_result.error_msg')
        message = "The response contains not empty ErrorMsg: `#{error_msg}`"
        mismatch(message, caller)
        Result.error(:not_empty_error_msg, message)
      end
    end
  end
end
