module Ciirus
  module Commands
    #  +Ciirus::Commands::CleaningFee+
    #
    # This class is responsible for fetching property cleaning fee information
    # from Ciirus API, parsing the response and building the result.
    #
    # Usage
    #
    #   result = Ciirus::Commands::CleaningFeeFetcher.new(credentials).fetch(property_id)
    #   if result.success?
    #     result.value
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the +CleaningFee+.
    class CleaningFeeFetcher < BaseCommand

      OPERATION_NAME = :get_cleaning_fee

      def call(property_id)
        message = xml_builder.cleaning_fee(property_id)
        result = additional_remote_call(message)
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
        @mapper ||= Ciirus::Mappers::CleaningFee.new
      end

      def valid_result?(result_hash)
        error_msg = result_hash.get('get_cleaning_fee_response.get_cleaning_fee_result.error_msg')
        error_msg.nil? || error_msg.empty?
      end

      def error_result(result_hash)
        error_msg = result_hash.get('get_cleaning_fee_response.get_cleaning_fee_result.error_msg')
        message = "The response contains not empty ErrorMsg: `#{error_msg}`"
        mismatch(message, caller)
        Result.error(:not_empty_error_msg)
      end
    end
  end
end
