module THH
  module Commands
    # +THH::Commands::Cancel+
    #
    # This class is responsible for wrapping the logic related to cancel
    # a THH booking, parsing the response.
    #
    # Usage
    #
    #   command = THH::Commands::Cancel.new(credentials)
    #   result = command.call(booking_id)
    #
    #   if result.success?
    #     result.value # booking_id
    #   end
    #
    # The +call+ method returns a +Result+ object that, when successful,
    # encapsulates booking_id.
    class Cancel < BaseFetcher
      STATUS_FIELD = 'response.status'

      def call(booking_id)
        result = api_call(params(booking_id))
        return result unless result.success?

        response = Concierge::SafeAccessHash.new(result.value)
        result = validate_response(response, booking_id)
        return result unless result.success?

        Result.new(booking_id)
      end

      protected

      def action
        'book_cancel'
      end

      private

      def validate_response(response, booking_id)
        status = response.get(STATUS_FIELD)
        unless status
          return Result.error(:unrecognised_response, "Cancel booking `#{booking_id}` response does not contain `#{STATUS_FIELD}` field")
        end
        unless status == 'ok'
          return Result.error(:unrecognised_response, "Cancel booking `#{booking_id}` response contains unexpected value for `#{STATUS_FIELD}` field: `#{status}`")
        end
        Result.new(true)
      end

      def params(booking_id)
        { 'booking_id' => booking_id }
      end
    end
  end
end
