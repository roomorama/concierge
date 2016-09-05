module Woori
  module Mappers
    # +Woori::Mappers::Reservation+
    #
    # This class is responsible for building an object for representing
    # the status of the reservation (pending, confirmed, etc)
    class Reservation
      attr_reader :request_params, :result_hash

      # Initialize Reservation mapper
      #
      # Arguments:
      #
      #   * +request_params+ [Concierge::SafeAccessHash] reservation attributes
      #   * +result_hash+ [Concierge::SafeAccessHash] hash with reservation
      #                                               number
      def initialize(request_params, result_hash)
        @request_params = request_params
        @result_hash = result_hash
      end

      # Builds a reservation status object
      #
      # Returns +Reservation+ status object
      def build_reservation
        ::Reservation.new(
          request_params.to_h.merge!(reference_number: reservation_code)
        )
      end

      private
      def reservation_code
        result_hash.get("hash")
      end
    end
  end
end
