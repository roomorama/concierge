module Ciirus
  module Commands
    #  +Ciirus::Commands::SecurityDepositFetcher+
    #
    # This class is responsible for fetching property security deposit information
    # from Ciirus API, parsing the response and building the result.
    # It uses GetExtras Ciirus API method and extract information about security deposit
    # extra.
    #
    # Usage
    #
    #   result = Ciirus::Commands::SecurityDepositFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +Entities::Extra+ or nil if extra not found.
    class SecurityDepositFetcher < BaseCommand

      OPERATION_NAME = :get_extras

      def call(property_id)
        message = xml_builder.extras(property_id)
        result = remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            security_deposit = mapper.build(result_hash)
            Result.new(security_deposit)
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
        @mapper ||= Ciirus::Mappers::SecurityDeposit.new
      end

      def valid_result?(result_hash)
        error_msg = result_hash.get('get_extras_response.get_extras_result.error_msg')
        error_msg.nil? || error_msg.empty?
      end

      def error_result(result_hash)
        error_msg = result_hash.get('get_extras_response.get_extras_result.error_msg')
        message = "The response contains not empty ErrorMsg: `#{error_msg}`"
        mismatch(message, caller)
        Result.error(:not_empty_error_msg)
      end
    end
  end
end
