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

      PROPERTY_DELETED_MESSAGE = 'Error (1012-CS) This property has been deleted. Please contact the inventory supplier.'

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
        error_msg.nil? || error_msg.empty? || error_msg == PROPERTY_DELETED_MESSAGE
      end

      def error_result(result_hash)
        error_msg = result_hash.get('get_property_permissions_response.get_property_permissions_result.error_msg')
        message = "The response contains not empty ErrorMsg: `#{error_msg}`"
        mismatch(message, caller)
        Result.error(:not_empty_error_msg)
      end
    end
  end
end
