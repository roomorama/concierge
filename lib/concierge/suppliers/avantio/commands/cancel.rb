module Avantio
  module Commands
    # +Avantio::Commands::Cancel+
    #
    # This class is responsible for wrapping the logic related to cancel
    # a Avantio booking, parsing the response.
    #
    # Usage
    #
    #   command = Avantio::Commands::Cancel.new(credentials)
    #   result = command.call(reservation_id)
    #
    #   if result.success?
    #     result.value # reservation_id
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the cancelled reservation_id.
    class Cancel

      OPERATION_NAME = :cancel_booking

      attr_reader :credentials

      def initialize(credentials)
        @credentials = credentials
      end

      def call(booking_code)
        message = xml_builder.cancel(booking_code)
        result = soap_client.call(OPERATION_NAME, message)
        return result unless result.success?

        result_hash = to_safe_hash(result.value)
        return error_result(result_hash) unless valid_result?(result_hash)

        Result.new(booking_code)
      end

      private

      def xml_builder
        @xml_builder ||= Avantio::XMLBuilder.new(credentials)
      end

      def soap_client
        @soap_client ||= Avantio::SoapClient.new
      end

      def valid_result?(result_hash)
        fetch_succeed(result_hash)
      end

      def error_result(result_hash)
        errors = {
          Succeed:  fetch_succeed(result_hash),
          ErrorList: fetch_error_list_as_string(result_hash)
        }

        parts = ['The `cancel_booking` response contains unexpected data:']
        errors.each do |label, field|
          unless field.nil?
            parts << "#{label}: `#{field}`"
          end
        end
        message = parts.join("\n")

        mismatch(message, caller)
        Result.error(:unexpected_response, message)
      end

      def fetch_succeed(result_hash)
        result_hash.get('cancel_booking_rs.succeed')
      end

      def fetch_error_list_as_string(result_hash)
        Array(result_hash.get('cancel_booking_rs.error_list.error')).map do |error|
          "ErrorId: #{error[:error_id]}, ErrorMessage: #{error[:error_message]}"
        end.join("\n")
      end

      def to_safe_hash(hash)
        Concierge::SafeAccessHash.new(hash)
      end

      def mismatch(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message:   message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end
