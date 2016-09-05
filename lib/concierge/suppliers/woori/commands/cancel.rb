module Woori
  module Commands
    # +Woori::Commands::Cancel+
    #
    # This class is responsible for wrapping the logic related to cancellations
    # rooms for Woori
    #
    # Woori documentation describes two similar endpoints:
    # * cancel (reservation/cancel)
    # * cancelcharge (reservation/cancelcharge)
    #
    # Real cancellation of already booked rooms is performed by cancel,
    # so this class uses this endpoint.
    class Cancel < BaseFetcher
      include Concierge::JSON

      ENDPOINT = "reservation/cancel"

      # Cancels reservation by its id (reservation code)
      #
      # Arguments
      #
      #   * +reference_number+ [String] reservation id
      #
      # Usage
      #
      #   command = Woori::Commands::Cancel.new(credentials)
      #   result = command.call("w_WP201608011845462029")
      #
      # Returns a +Result+ wrapping a +reference_number+ of the cancelled
      # reservation when operation succeeds.
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call(reference_number)
        params = build_request_params(reference_number)

        result = http.post(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)

          if decoded_result.success?
            safe_hash = Concierge::SafeAccessHash.new(decoded_result.value)

            if safe_hash.get("message") == "success"
              Result.new(reference_number)
            else
              reservation_cancel_error(reference_number)
            end
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params(reference_number)
        { reservationNo: reference_number }
      end

      def reservation_cancel_error(id)
        message = "Unknown error during cancellation of reservation `#{id}`"
        augment_with_error(message, caller)
        Result.error(:reservation_cancel_error)
      end

      def augment_with_error(message, backtrace)
        response_mismatch = Concierge::Context::ResponseMismatch.new(
          message: message,
          backtrace: backtrace
        )

        Concierge.context.augment(response_mismatch)
      end
    end
  end
end
