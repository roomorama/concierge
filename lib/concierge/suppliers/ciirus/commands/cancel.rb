module Ciirus
  module Commands
    # +Ciirus::Commands::Cancel+
    #
    # This class is responsible for wrapping the logic related to cancel
    # a Ciirus booking, parsing the response.
    #
    # Usage
    #
    #   command = Ciirus::Commands::Cancel.new(credentials)
    #   result = command.call(reservation_id)
    #
    #   if result.success?
    #     result.value # reservation_id
    #   end
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates the cancelled reservation_id.
    class Cancel < BaseCommand

      OPERATION_NAME = :cancel_booking

      def call(reservation_id)
        message = xml_builder.cancel(reservation_id)
        result = additional_remote_call(message)
        if result.success?
          result_hash = to_safe_hash(result.value)
          if valid_result?(result_hash)
            Result.new(reservation_id)
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
        @mapper ||= Ciirus::Mappers::RoomoramaReservation.new
      end

      def valid_result?(result_hash)
        cancel_booking_result = extract_cancel_booking_result(result_hash)
        cancel_booking_result.nil?
      end

      def error_result(result_hash)
        cancel_booking_result = extract_cancel_booking_result(result_hash)

        message = "The response contains unexpected response: #{cancel_booking_result}"

        mismatch(message, caller)
        Result.error(:unexpected_response)
      end

      def extract_cancel_booking_result(result_hash)
        result_hash.get('cancel_booking_response.cancel_booking_result')
      end
    end
  end
end
