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
    # Real cancellation of already booked rooms is performed by cancelcharge,
    # so this class uses this endpoint.
    class Cancel < BaseFetcher
      include Concierge::JSON

      ENDPOINT = "reservation/cancelcharge"

      # Cancels reservation by its id (reservation code)
      #
      # Arguments
      #
      #   * +reservation_id+ [String] reservation id
      #
      # Usage
      #
      #   command = Woori::Commands::Cancel.new(credentials)
      #   result = command.call("w_WP201608011845462029")
      #
      # Returns a +Result+ wrapping a +reservation_id+ of the cancelled
      # reservation when operation succeeds.
      # Returns a +Result+ with +Result::Error+ when operation fails
      def call(reservation_id)
        params = build_request_params(reservation_id)
        result = http.get(ENDPOINT, params, headers)

        if result.success?
          decoded_result = json_decode(result.value.body)

          if decoded_result.success?
            Concierge::SafeAccessHash.new(decoded_result.value)
            Result.new(reservation_id)
          else
            decoded_result
          end
        else
          result
        end
      end

      private
      def build_request_params(reservation_id)
        { reservationNo: reservation_id }
      end
    end
  end
end
